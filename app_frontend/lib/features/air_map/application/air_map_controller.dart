import 'dart:async';

import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/data/air_map_repository_impl.dart';
import 'package:hawa_app/features/air_map/data/geocoding_remote_source.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'air_map_controller.g.dart';

/// The ML air layers (twin grid, hotspots, forecast), cached; kept alive across tab switches.
@Riverpod(keepAlive: true)
class AirMapController extends _$AirMapController {
  /// Stale-while-revalidate: the cached map renders at once; a stale one refreshes behind it.
  @override
  Future<AirMapData> build() async {
    final repo = ref.watch(airMapRepositoryProvider);
    final cached = await repo.cached();
    if (cached == null) return repo.load();
    if (!await repo.isFresh()) unawaited(Future.microtask(refresh));
    return cached;
  }

  /// Pull to refresh / retry: always goes to the backend; keeps the old layers on failure.
  Future<void> refresh() async {
    final next = await AsyncValue.guard(() => ref.read(airMapRepositoryProvider).load(force: true));
    if (ref.mounted) state = next;
  }
}

class AirLayersState {
  const AirLayersState({
    this.heatmap = true,
    this.hotspots = true,
    this.hoursAhead = 0,
    this.relative = true,
  });

  final bool heatmap;
  final bool hotspots;

  /// Colour the field relative to the rest of the city now (default), or by CPCB AQI bands.
  /// On a bad day the whole city is one AQI band, so the relative scale is what shows which
  /// streets are cleaner.
  final bool relative;

  /// 0 = now; else the forecast hour the map shows.
  final int hoursAhead;

  AirLayersState copyWith({bool? heatmap, bool? hotspots, int? hoursAhead, bool? relative}) =>
      AirLayersState(
        heatmap: heatmap ?? this.heatmap,
        hotspots: hotspots ?? this.hotspots,
        hoursAhead: hoursAhead ?? this.hoursAhead,
        relative: relative ?? this.relative,
      );
}

/// Layer toggles and the forecast time slider.
@Riverpod(keepAlive: true)
class AirLayers extends _$AirLayers {
  static const hourSteps = [0, 3, 6, 12, 24];

  @override
  AirLayersState build() => const AirLayersState();

  void toggleHeatmap() => state = state.copyWith(heatmap: !state.heatmap);

  void toggleHotspots() => state = state.copyWith(hotspots: !state.hotspots);

  void setHours(int h) => state = state.copyWith(hoursAhead: h);

  void toggleScale() => state = state.copyWith(relative: !state.relative);
}

/// The user's position, only on request ("my location" / "Your location"). It stays on the phone
/// except as a route start sent to the router.
@Riverpod(keepAlive: true)
class MyLocation extends _$MyLocation {
  @override
  GeoPoint? build() => null;

  Future<GeoPoint?> locate() async {
    final fix = await ref
        .read(locationServiceProvider)
        .currentFix(timeout: const Duration(seconds: 10));
    if (!ref.mounted) return null;
    if (fix != null) state = fix.point;
    return fix?.point;
  }
}

/// Place search results for the route planner (debounced by the caller).
@riverpod
Future<List<Place>> placeSearch(Ref ref, String query) =>
    ref.watch(geocodingRemoteSourceProvider).search(query, near: ref.read(myLocationProvider));
