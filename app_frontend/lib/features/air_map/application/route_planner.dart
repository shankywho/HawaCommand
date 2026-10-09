import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/application/air_map_controller.dart';
import 'package:hawa_app/features/air_map/data/routing_remote_source.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/departure_planner.dart';
import 'package:hawa_app/features/air_map/domain/detour_planner.dart';
import 'package:hawa_app/features/air_map/domain/exposure_scorer.dart';
import 'package:hawa_app/features/air_map/domain/place.dart';
import 'package:hawa_app/features/air_map/domain/route_option.dart';
import 'package:hawa_app/features/air_map/domain/travel_mode.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'route_planner.g.dart';

class RoutePlanState {
  const RoutePlanState({
    this.origin,
    this.destination,
    this.mode = TravelMode.twoWheeler,
    this.departureHours = 0,
    this.routes = const AsyncData([]),
    this.selected = 0,
    this.departures = const [],
  });

  final Place? origin;
  final Place? destination;
  final TravelMode mode;

  /// Hours from now the trip starts (0 = now).
  final int departureHours;
  final AsyncValue<List<RouteOption>> routes;
  final int selected;
  final List<DepartureOption> departures;

  bool get isActive => origin != null || destination != null;

  bool get canPlan => origin != null && destination != null;

  RouteOption? get selectedRoute {
    final list = routes.value;
    if (list == null || list.isEmpty) return null;
    return list[selected.clamp(0, list.length - 1)];
  }

  RoutePlanState copyWith({
    Place? origin,
    Place? destination,
    TravelMode? mode,
    int? departureHours,
    AsyncValue<List<RouteOption>>? routes,
    int? selected,
    List<DepartureOption>? departures,
  }) => RoutePlanState(
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    mode: mode ?? this.mode,
    departureHours: departureHours ?? this.departureHours,
    routes: routes ?? this.routes,
    selected: selected ?? this.selected,
    departures: departures ?? this.departures,
  );
}

/// Clean-air route planning: road routes from the router (plus ML-chosen detours around the
/// dirtiest stretch), each scored by the PM2.5 dose along it at the hour it would be travelled.
@Riverpod(keepAlive: true)
class RoutePlanner extends _$RoutePlanner {
  int _generation = 0;

  /// Detours longer than this multiple of the fastest time are dropped.
  static const maxDetourRatio = 1.8;

  @override
  RoutePlanState build() => const RoutePlanState();

  Future<void> setOrigin(Place p) async {
    state = state.copyWith(origin: p);
    await _planIfReady();
  }

  Future<void> setDestination(Place p) async {
    state = state.copyWith(destination: p);
    await _planIfReady();
  }

  Future<void> swap() async {
    final o = state.origin;
    final d = state.destination;
    state = RoutePlanState(
      origin: d,
      destination: o,
      mode: state.mode,
      departureHours: state.departureHours,
    );
    await _planIfReady();
  }

  Future<void> setMode(TravelMode mode) async {
    if (mode == state.mode) return;
    state = state.copyWith(mode: mode);
    await _planIfReady();
  }

  /// Re-scores the current routes for a later start (no new router call).
  Future<void> setDeparture(int hours) async {
    state = state.copyWith(departureHours: hours);
    final data = ref.read(airMapControllerProvider).value;
    final routes = state.routes.value;
    if (data == null || routes == null || routes.isEmpty) return;
    final rescored = ExposureScorer.rank([
      for (final r in routes) r.withExposure(_score(data, r.geometry, r.durationS)),
    ]);
    state = state.copyWith(routes: AsyncData(rescored), selected: 0);
  }

  void select(int index) {
    state = state.copyWith(selected: index);
    _updateDepartures();
  }

  void clear() {
    _generation++;
    state = RoutePlanState(mode: state.mode);
  }

  Future<void> retry() => _planIfReady();

  Future<void> _planIfReady() async {
    if (!state.canPlan) return;
    final gen = ++_generation;
    state = state.copyWith(routes: const AsyncLoading(), selected: 0, departures: const []);
    final result = await AsyncValue.guard(_plan);
    if (gen != _generation || !ref.mounted) return;
    state = state.copyWith(routes: result, selected: 0);
    _updateDepartures();
  }

  Future<List<RouteOption>> _plan() async {
    final data = await ref.read(airMapControllerProvider.future);
    final routing = ref.read(routingRemoteSourceProvider);
    final o = state.origin!.point;
    final d = state.destination!.point;
    final mode = state.mode;
    if (Geo.distanceM(o, d) < 50) throw const ValidationFailure([], code: 'same_place');

    final base = await routing.route([o, d], mode, alternatives: true);
    if (base.isEmpty) throw const NotFoundFailure(code: 'no_route');
    double? field(GeoPoint p, double h) => data.pm25At(p, h + state.departureHours);
    final vias = DetourPlanner.viaPoints(
      route: base.first.geometry,
      field: field,
      hotspots: data.hotspots,
    );
    final detours = await Future.wait([
      for (final v in vias)
        () async {
          try {
            final r = await routing.route([o, v, d], mode);
            return r.isEmpty ? null : (r.first, v);
          } on Object {
            return null; // a detour is optional; the base routes still answer
          }
        }(),
    ]);

    final candidates = <(RawRoute, GeoPoint?)>[
      for (final r in base) (r, null),
      for (final r in detours) ?r,
    ];
    final fastest = candidates.map((c) => c.$1.durationS).reduce((a, b) => a < b ? a : b);
    final kept = ExposureScorer.dedupe(
      [
        for (final c in candidates)
          if (c.$1.durationS <= fastest * maxDetourRatio) c,
      ],
      (c) => c.$1.distanceM,
      (c) => c.$1.durationS,
    );
    final options = [
      for (var i = 0; i < kept.length; i++)
        RouteOption(
          id: 'r$i',
          geometry: kept[i].$1.geometry,
          distanceM: kept[i].$1.distanceM,
          durationS: kept[i].$1.durationS,
          via: kept[i].$2,
          exposure: _score(
            data,
            kept[i].$1.geometry,
            kept[i].$1.durationS,
            kept[i].$1.segmentDurationsS,
          ),
        ),
    ];
    return ExposureScorer.rank(options);
  }

  RouteExposure _score(
    AirMapData data,
    List<GeoPoint> geometry,
    double durationS, [
    List<double>? segs,
  ]) => ExposureScorer.score(
    geometry: geometry,
    durationS: durationS,
    segmentDurationsS: segs,
    field: data.pm25At,
    band: data.forecast?.bandAt,
    mode: state.mode,
    departureHoursAhead: state.departureHours.toDouble(),
  );

  void _updateDepartures() {
    final route = state.selectedRoute;
    final data = ref.read(airMapControllerProvider).value;
    if (route == null || data == null) {
      state = state.copyWith(departures: const []);
      return;
    }
    state = state.copyWith(
      departures: DeparturePlanner.options(route: route, field: data.pm25At, mode: state.mode),
    );
  }
}
