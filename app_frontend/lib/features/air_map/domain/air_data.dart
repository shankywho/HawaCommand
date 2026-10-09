import 'dart:math' as math;

import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';

/// One hour of a P10/P50/P90 forecast.
class ForecastPoint {
  const ForecastPoint({required this.h, required this.p10, required this.p50, required this.p90});

  final int h;
  final double p10;
  final double p50;
  final double p90;
}

class HotspotSchool {
  const HotspotSchool({required this.name, required this.distanceKm, this.assemblyAt});

  final String name;
  final double distanceKm;
  final String? assemblyAt;
}

/// A ranked severe-exposure hotspot from `/v1/hotspots` (ML ranking + cause attribution).
class Hotspot {
  const Hotspot({
    required this.cellId,
    required this.place,
    required this.location,
    required this.pm25,
    required this.category,
    required this.cause,
    required this.causeConfidence,
    required this.confidence,
    required this.rank,
    this.ward,
    this.exposurePersonHours,
    this.schools = const [],
    this.forecast = const [],
    this.suspectBearing,
    this.suspectDistanceKm,
  });

  final String cellId;
  final String place;
  final String? ward;
  final GeoPoint location;
  final double pm25;

  /// The server's band word ("Severe") mapped to the CPCB category.
  final AqiCategory category;
  final CauseLabel cause;
  final double causeConfidence;
  final double confidence;
  final int rank;
  final double? exposurePersonHours;
  final List<HotspotSchool> schools;
  final List<ForecastPoint> forecast;
  final String? suspectBearing;
  final double? suspectDistanceKm;

  /// Forecast P50 [hoursAhead] from now, else the current value.
  double pm25At(double hoursAhead) {
    if (forecast.isEmpty) return pm25;
    final h = hoursAhead.round();
    for (final f in forecast) {
      if (f.h == h) return f.p50;
    }
    return forecast.last.p50;
  }
}

/// City-wide 72 h forecast and GRAP outlook from `/v1/forecast`.
class CityForecast {
  const CityForecast({
    required this.issuedAt,
    required this.series,
    this.grapStage = 0,
    this.grapProbability,
    this.grapHeadline,
  });

  final DateTime issuedAt;
  final List<ForecastPoint> series;
  final int grapStage;
  final double? grapProbability;
  final String? grapHeadline;

  ForecastPoint? _at(double hoursAhead) {
    if (series.isEmpty) return null;
    final h = hoursAhead.clamp(0, series.last.h).round();
    return series.firstWhere((p) => p.h == h, orElse: () => series.last);
  }

  /// How much worse (> 1) or better (< 1) the city is expected to be [hoursAhead] from now,
  /// relative to now (P50 ratio, clamped). Applied to the twin field for departure planning.
  double factorAt(double hoursAhead) {
    final now = _at(0);
    final then = _at(hoursAhead);
    if (now == null || then == null || now.p50 <= 0) return 1;
    return (then.p50 / now.p50).clamp(0.4, 2.5);
  }

  /// P10/P90 relative to P50 at [hoursAhead]: the uncertainty band applied to doses.
  (double low, double high) bandAt(double hoursAhead) {
    final p = _at(hoursAhead);
    if (p == null || p.p50 <= 0) return (0.8, 1.25);
    return (math.min(1, p.p10 / p.p50), math.max(1, p.p90 / p.p50));
  }

  double? get nowP50 => _at(0)?.p50;
}

/// Everything the air map draws.
class AirMapData {
  const AirMapData({
    required this.grid,
    required this.hotspots,
    required this.forecast,
    required this.fetchedAt,
    this.fromCache = false,
    this.error,
  });

  final PollutionGrid grid;
  final List<Hotspot> hotspots;
  final CityForecast? forecast;
  final DateTime fetchedAt;

  /// Served from the local cache because the backend could not be reached.
  final bool fromCache;
  final Object? error;

  bool get isSimulated => grid.isSimulated;

  /// Estimated PM2.5 at [p], [hoursAhead] from now: the twin value scaled by the city forecast
  /// trend, raised towards a nearby hotspot's own forecast (hotspots are sharper than the 500 m
  /// twin). Null outside the grid.
  double? pm25At(GeoPoint p, [double hoursAhead = 0]) {
    final base = grid.pm25At(p);
    if (base == null) return null;
    var value = base * (forecast?.factorAt(hoursAhead) ?? 1);
    for (final h in hotspots) {
      final d = Geo.distanceM(p, h.location);
      if (d > hotspotRadiusM) continue;
      // Linear blend from the hotspot value at its centre to the twin at the radius.
      final w = 1 - d / hotspotRadiusM;
      final hv = h.pm25At(hoursAhead);
      value = math.max(value, value * (1 - w) + hv * w);
    }
    return value;
  }

  /// Hotspots are drawn and weighted out to this radius.
  static const hotspotRadiusM = 700.0;

  AirMapData copyWith({bool? fromCache, Object? error}) => AirMapData(
    grid: grid,
    hotspots: hotspots,
    forecast: forecast,
    fetchedAt: fetchedAt,
    fromCache: fromCache ?? this.fromCache,
    error: error ?? this.error,
  );
}
