import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';

/// Tolerant JSON → domain mapping for the command-center payloads (unknown fields ignored,
/// unknown enum words → `unknown`).
abstract final class AirMapMapper {
  static String _wire(Object? v) =>
      (v as String? ?? '').trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');

  static AqiCategory category(Object? band) => AqiCategory.fromWire(_wire(band));

  static CauseLabel cause(Object? v) => CauseLabel.fromWire(_wire(v));

  static double _d(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;

  /// Forecast points with the quantiles put in order (some payloads swap P10 and P90).
  static List<ForecastPoint> series(Object? raw) => [
    for (final p in (raw as List<Object?>?) ?? const [])
      if (p is Map<String, Object?>)
        () {
          final q = [_d(p['p10']), _d(p['p50']), _d(p['p90'])]..sort();
          return ForecastPoint(h: (p['h'] as num?)?.toInt() ?? 0, p10: q[0], p50: q[1], p90: q[2]);
        }(),
  ];

  static GeoPoint? _at(Object? at) {
    if (at is List && at.length >= 2 && at[0] is num && at[1] is num) {
      return GeoPoint(lat: (at[1] as num).toDouble(), lon: (at[0] as num).toDouble());
    }
    if (at is Map<String, Object?> && at['lat'] is num && at['lon'] is num) {
      return GeoPoint(lat: _d(at['lat']), lon: _d(at['lon']));
    }
    return null;
  }

  static List<Hotspot> hotspots(Map<String, Object?> json) {
    final out = <Hotspot>[];
    for (final item in (json['items'] as List<Object?>?) ?? const []) {
      if (item is! Map<String, Object?>) continue;
      final at = _at(item['at']);
      if (at == null) continue;
      final suspect = item['suspectPin'] as Map<String, Object?>?;
      out.add(
        Hotspot(
          cellId: item['cellId'] as String? ?? '',
          place: item['place'] as String? ?? item['placeFull'] as String? ?? '',
          ward: item['ward'] as String?,
          location: at,
          pm25: _d(item['pm25']),
          category: category(item['band']),
          cause: cause(item['cause']),
          causeConfidence: _d(item['causeConf'], _d(item['conf'])),
          confidence: _d(item['conf'], 0.5),
          rank: (item['rank'] as num?)?.toInt() ?? out.length + 1,
          exposurePersonHours: (item['exposurePh'] as num?)?.toDouble(),
          schools: [
            for (final s in (item['schools'] as List<Object?>?) ?? const [])
              if (s is Map<String, Object?>)
                HotspotSchool(
                  name: s['name'] as String? ?? '',
                  distanceKm: _d(s['distanceKm']),
                  assemblyAt: s['assemblyAt'] as String?,
                ),
          ],
          forecast: series(item['forecast']),
          suspectBearing: suspect?['bearing'] as String?,
          suspectDistanceKm: (suspect?['distanceKm'] as num?)?.toDouble(),
        ),
      );
    }
    out.sort((a, b) => a.rank.compareTo(b.rank));
    return out;
  }

  /// GRAP stage from "II" / "2" / 2.
  static int grapStage(Object? v) {
    if (v is num) return v.toInt().clamp(0, 4);
    final s = (v as String? ?? '').trim().toUpperCase();
    return switch (s) {
      'I' || '1' => 1,
      'II' || '2' => 2,
      'III' || '3' => 3,
      'IV' || '4' => 4,
      _ => 0,
    };
  }

  static CityForecast forecast(Map<String, Object?> json) {
    final grap = json['grap'] as Map<String, Object?>?;
    return CityForecast(
      issuedAt:
          DateTime.tryParse(json['issuedAt'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      series: series(json['series']),
      grapStage: grapStage(grap?['stage']),
      grapProbability: (grap?['probability'] as num?)?.toDouble(),
      grapHeadline: grap?['headline'] as String?,
    );
  }
}
