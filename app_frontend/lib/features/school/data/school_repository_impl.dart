import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/school/data/school_remote_source.dart';
import 'package:hawa_app/features/school/domain/school_models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'school_repository_impl.g.dart';

/// S1–S3, cache first (`cached_payloads`): each read renders from the cache and refreshes in the
/// background; failures keep the cached copy.
class SchoolRepository {
  SchoolRepository({required this.db, required this.remote, required this.now});

  final AppDatabase db;
  final SchoolRemoteSource remote;
  final DateTime Function() now;

  static const meKey = 'school:me';
  static String safeKey(String date) => 'school:safe:$date';
  static const ioKey = 'school:indoor_outdoor';
  static const grapKey = 'school:grap';
  static const forecastKey = 'school:forecast';

  Stream<SchoolInfo?> watchMe() =>
      db.cacheDao.watchJson(meKey).map((c) => c == null ? null : SchoolInfo.fromJson(c.json));

  Future<SchoolInfo?> refreshMe() async {
    final json = await remote.me();
    await db.cacheDao.putJson(meKey, json, fetchedAt: now().toUtc());
    return SchoolInfo.fromJson(json);
  }

  /// Null data with `not_issued` when the server has no issue for the date yet.
  Stream<SafeWindowDay?> watchSafe(String date) => db.cacheDao
      .watchJson(safeKey(date))
      .map(
        (c) => c == null || c.json['not_issued'] == true ? null : SafeWindowDay.fromJson(c.json),
      );

  Future<void> refreshSafe(String schoolId, String date) async {
    try {
      final json = await remote.safeWindow(schoolId, date);
      await db.cacheDao.putJson(safeKey(date), json, fetchedAt: now().toUtc());
    } on NotFoundFailure {
      await db.cacheDao.putJson(safeKey(date), {'not_issued': true}, fetchedAt: now().toUtc());
    }
  }

  Stream<IndoorOutdoor?> watchIndoor() =>
      db.cacheDao.watchJson(ioKey).map((c) => c == null ? null : IndoorOutdoor.fromJson(c.json));

  Future<void> refreshIndoor(String schoolId) async =>
      db.cacheDao.putJson(ioKey, await remote.indoorOutdoor(schoolId), fetchedAt: now().toUtc());

  Stream<List<GrapDay>> watchGrap() => db.cacheDao
      .watchJson(grapKey)
      .map((c) => c == null ? const [] : GrapDay.listFromJson(c.json));

  Future<void> refreshGrap(String ward) async =>
      db.cacheDao.putJson(grapKey, await remote.grapOutlook(ward), fetchedAt: now().toUtc());

  Stream<CellForecast?> watchForecast() => db.cacheDao
      .watchJson(forecastKey)
      .map((c) => c == null ? null : CellForecast.fromJson(c.json));

  Future<void> refreshForecast(String cellId) async =>
      db.cacheDao.putJson(forecastKey, await remote.forecast(cellId), fetchedAt: now().toUtc());

  Stream<DateTime?> watchFetchedAt(String key) =>
      db.cacheDao.watchJson(key).map((c) => c?.fetchedAt);
}

@riverpod
SchoolRepository schoolRepository(Ref ref) => SchoolRepository(
  db: ref.watch(appDatabaseProvider),
  remote: ref.watch(schoolRemoteSourceProvider),
  now: ref.watch(appClockProvider).now,
);
