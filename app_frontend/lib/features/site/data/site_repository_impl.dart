import 'dart:async';

import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/network/server_clock.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/daos/cache_dao.dart';
import 'package:hawa_app/features/site/data/site_mapper.dart';
import 'package:hawa_app/features/site/data/site_remote_source.dart';
import 'package:hawa_app/features/site/domain/site_repository.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'site_repository_impl.g.dart';

/// Site score cache (OFFLINE_AND_SYNC §2: `cached_payloads`, kept 7 days, stale after 24 h).
class SiteRepositoryImpl implements SiteRepository {
  SiteRepositoryImpl({required this.remote, required this.db, required this.clock});

  final SiteRemoteSource remote;
  final AppDatabase db;
  final ServerClock clock;

  /// `cached_payloads` key and `sync_state` scope.
  static const cacheKey = 'site_me';
  static const scope = 'site';
  static const keepFor = Duration(days: 7);

  static final _log = Logger('site');

  Future<void>? _inFlight;

  @override
  Stream<SiteSnapshot?> watch() => db.cacheDao.watchJson(cacheKey).map(_decode);

  /// Single-flight: a refresh while one is running joins it (OFFLINE_AND_SYNC §4).
  @override
  Future<void> refresh() => _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<void> _refresh() async {
    final now = clock.now();
    try {
      final out = await remote.me();
      await db.transaction(() async {
        await db.cacheDao.putJson(
          cacheKey,
          out.toJson(),
          fetchedAt: now,
          expiresAt: now.add(keepFor),
          isSimulated: out.isSimulated,
        );
        await db.syncStateDao.markSuccess(scope, now);
      });
    } on Object catch (e) {
      final failure = failureOf(e);
      await db.syncStateDao.markAttempt(
        scope,
        now,
        errorCode: failure.code ?? failure.runtimeType.toString(),
      );
      throw failure;
    }
  }

  SiteSnapshot? _decode(CachedJson? cached) {
    if (cached == null) return null;
    try {
      return SiteSnapshot(site: SiteMapper.fromJson(cached.json), fetchedAt: cached.fetchedAt);
    } on Object catch (e) {
      // A payload from an older app version that no longer parses: treat as no cache.
      _log.warning('cached site payload unreadable', e);
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
SiteRepository siteRepository(Ref ref) => SiteRepositoryImpl(
  remote: ref.watch(siteRemoteSourceProvider),
  db: ref.watch(appDatabaseProvider),
  clock: ref.watch(serverClockProvider),
);
