import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';

enum RouteTag { recommended, cleanest, fastest }

/// A run of consecutive route points (≤ ~400 m, one AQI category): the coloured route line.
class ExposureRun {
  const ExposureRun({required this.points, required this.category, required this.avgPm25});

  final List<GeoPoint> points;
  final AqiCategory category;
  final double avgPm25;
}

/// Estimated exposure along a route at a given departure time.
class RouteExposure {
  const RouteExposure({
    required this.avgPm25,
    required this.maxPm25,
    required this.doseUg,
    required this.doseLowUg,
    required this.doseHighUg,
    required this.redZoneMinutes,
    required this.runs,
    required this.coverage,
  });

  /// Time-weighted mean outdoor PM2.5 (µg/m³).
  final double avgPm25;
  final double maxPm25;

  /// PM2.5 inhaled (µg): concentration × infiltration × breathing rate × time.
  final double doseUg;
  final double doseLowUg;
  final double doseHighUg;

  /// Minutes in very poor or severe air (PM2.5 > 120 µg/m³).
  final double redZoneMinutes;
  final List<ExposureRun> runs;

  /// Share of the route inside the twin grid (0–1); below 0.6 the estimate is weak.
  final double coverage;
}

/// One candidate route with its ML exposure score.
class RouteOption {
  const RouteOption({
    required this.id,
    required this.geometry,
    required this.distanceM,
    required this.durationS,
    required this.exposure,
    this.via,
    this.tags = const {},
  });

  final String id;
  final List<GeoPoint> geometry;
  final double distanceM;
  final double durationS;
  final RouteExposure exposure;

  /// The clean-air detour waypoint this route was asked to pass, if any.
  final GeoPoint? via;
  final Set<RouteTag> tags;

  RouteOption withTags(Set<RouteTag> t) => RouteOption(
    id: id,
    geometry: geometry,
    distanceM: distanceM,
    durationS: durationS,
    exposure: exposure,
    via: via,
    tags: t,
  );

  RouteOption withExposure(RouteExposure e) => RouteOption(
    id: id,
    geometry: geometry,
    distanceM: distanceM,
    durationS: durationS,
    exposure: e,
    via: via,
    tags: tags,
  );
}
