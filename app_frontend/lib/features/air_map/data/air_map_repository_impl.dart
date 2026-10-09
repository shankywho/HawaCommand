import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/daos/cache_dao.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/air_map/data/air_map_mapper.dart';
import 'package:hawa_app/features/air_map/data/air_map_remote_source.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/air_map_repository.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'air_map_repository_impl.g.dart';

/// Stale-while-revalidate over `cached_payloads` (OFFLINE_AND_SYNC §2): the twin grid is kept
/// 15 min, hotspots 10 min, the forecast 30 min; anything older is still shown offline, flagged.
class AirMapRepositoryImpl implements AirMapRepository {
  AirMapRepositoryImpl({required this.remote, required this.cache, required this.now});

  final AirMapRemoteSource remote;
  final CacheDao cache;
  final DateTime Function() now;

  static const gridKey = 'air_map:twin_grid';
  static const hotspotsKey = 'air_map:hotspots';
  static const forecastKey = 'air_map:forecast';
  static const gridTtl = Duration(minutes: 15);
  static const hotspotsTtl = Duration(minutes: 10);
  static const forecastTtl = Duration(minutes: 30);

  @override
  Future<AirMapData?> cached() async {
    final grid = await cache.getJson(gridKey);
    if (grid == null) return null;
    return _assemble(
      grid,
      await cache.getJson(hotspotsKey),
      await cache.getJson(forecastKey),
      fetchedAt: grid.fetchedAt,
    );
  }

  @override
  Future<bool> isFresh() async {
    final t = now().toUtc();
    bool fresh(CachedJson? c, Duration ttl) => c != null && t.difference(c.fetchedAt) < ttl;
    return fresh(await cache.getJson(gridKey), gridTtl) &&
        fresh(await cache.getJson(hotspotsKey), hotspotsTtl) &&
        fresh(await cache.getJson(forecastKey), forecastTtl);
  }

  @override
  Future<AirMapData> load({bool force = false}) async {
    final t = now().toUtc();
    final cachedGrid = await cache.getJson(gridKey);
    final cachedHot = await cache.getJson(hotspotsKey);
    final cachedFc = await cache.getJson(forecastKey);
    bool fresh(CachedJson? c, Duration ttl) => c != null && t.difference(c.fetchedAt) < ttl;

    if (!force &&
        fresh(cachedGrid, gridTtl) &&
        fresh(cachedHot, hotspotsTtl) &&
        fresh(cachedFc, forecastTtl)) {
      return _assemble(cachedGrid!, cachedHot, cachedFc, fetchedAt: cachedGrid.fetchedAt);
    }

    try {
      final results = await Future.wait<Object>([
        if (force || !fresh(cachedGrid, gridTtl))
          remote.grid()
        else
          Future.value(PollutionGrid.fromCompact(cachedGrid!.json)),
        if (force || !fresh(cachedHot, hotspotsTtl))
          remote.hotspots()
        else
          Future.value(cachedHot!.json),
        if (force || !fresh(cachedFc, forecastTtl))
          remote.forecast()
        else
          Future.value(cachedFc!.json),
      ]);
      final grid = results[0] as PollutionGrid;
      final hot = results[1] as Map<String, Object?>;
      final fc = results[2] as Map<String, Object?>;
      await cache.putJson(gridKey, grid.toCompact(), fetchedAt: t, isSimulated: grid.isSimulated);
      await cache.putJson(
        hotspotsKey,
        hot,
        fetchedAt: t,
        isSimulated: hot['simulated'] as bool? ?? false,
      );
      await cache.putJson(forecastKey, fc, fetchedAt: t);
      return AirMapData(
        grid: grid,
        hotspots: AirMapMapper.hotspots(hot),
        forecast: AirMapMapper.forecast(fc),
        fetchedAt: t,
      );
    } on Object catch (e) {
      final failure = failureOf(e);
      if (cachedGrid == null) throw failure;
      return _assemble(cachedGrid, cachedHot, cachedFc, fetchedAt: cachedGrid.fetchedAt).copyWith(
        fromCache: true,
        error: failure,
      );
    }
  }

  AirMapData _assemble(
    CachedJson grid,
    CachedJson? hot,
    CachedJson? fc, {
    required DateTime fetchedAt,
  }) => AirMapData(
    grid: PollutionGrid.fromCompact(grid.json),
    hotspots: hot == null ? const [] : AirMapMapper.hotspots(hot.json),
    forecast: fc == null ? null : AirMapMapper.forecast(fc.json),
    fetchedAt: fetchedAt,
  );
}

@riverpod
AirMapRepository airMapRepository(Ref ref) => AirMapRepositoryImpl(
  remote: ref.watch(airMapRemoteSourceProvider),
  cache: ref.watch(appDatabaseProvider).cacheDao,
  now: ref.watch(appClockProvider).now,
);
