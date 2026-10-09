import 'dart:math' as math;

import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/citizen_air/data/open_air_remote_source.dart';

/// Air near me from what the backend serves today: the AI-ML twin cells (500 m) inside the
/// snapped box, with the cause of the nearest ranked hotspot. Shaped as the proposed
/// `/open/v1/air` FeatureCollection so the rest of the feature is unchanged when that endpoint
/// ships. Only the snapped box is sent (twin `bbox` is `min_lat,min_lon,max_lat,max_lon`).
class CommandCenterOpenAirSource implements OpenAirRemoteSource {
  CommandCenterOpenAirSource(this._api, [this._fallback]);

  final CommandCenterApi _api;
  final OpenAirRemoteSource? _fallback;

  /// Hotspot causes apply within this distance of a cell.
  static const causeRadiusM = 3000.0;

  @override
  Future<api.OpenAirOut> air(String bbox) async {
    try {
      final p = bbox.split(',').map(double.parse).toList(); // minLon,minLat,maxLon,maxLat
      final twinBox = '${p[1]},${p[0]},${p[3]},${p[2]}';
      final results = await Future.wait([_api.twin(bbox: twinBox, limit: 400), _api.hotspots()]);
      return api.OpenAirOut.fromJson(featureCollection(results[0], results[1]));
    } on Object catch (e) {
      if (_fallback != null) {
        try {
          return await _fallback!.air(bbox);
        } on Object {
          // ignore and throw original failure
        }
      }
      throw failureOf(e);
    }
  }


  /// Pure mapping (unit tested): twin cells + hotspots → open-air FeatureCollection JSON.
  static Map<String, Object?> featureCollection(
    Map<String, Object?> twin,
    Map<String, Object?> hotspots,
  ) {
    final cells = [
      for (final c in (twin['cells'] as List<Object?>?) ?? const [])
        if (c is Map<String, Object?>) c,
    ];
    final spots = [
      for (final h in (hotspots['items'] as List<Object?>?) ?? const [])
        if (h is Map<String, Object?> && h['at'] is List && (h['at']! as List).length >= 2) h,
    ];
    // Half-steps of the grid, to draw each cell's square.
    var dLat = 0.0045 / 2;
    var dLon = 0.0051 / 2;
    if (cells.length > 1) {
      final lats = cells.map((c) => (c['latitude']! as num).toDouble()).toSet().toList()..sort();
      final lons = cells.map((c) => (c['longitude']! as num).toDouble()).toSet().toList()..sort();
      if (lats.length > 1) dLat = (lats[1] - lats[0]) / 2;
      if (lons.length > 1) dLon = (lons[1] - lons[0]) / 2;
    }
    final simulated = hotspots['simulated'] as bool? ?? false;
    final features = <Map<String, Object?>>[];
    for (final c in cells) {
      final lat = (c['latitude']! as num).toDouble();
      final lon = (c['longitude']! as num).toDouble();
      final pm25 = (c['pm25_est'] as num?)?.toDouble();
      final pm10 = (c['pm10_est'] as num?)?.toDouble();
      final a25 = pm25 == null ? 0 : Aqi.fromPm25(pm25);
      final a10 = pm10 == null ? 0 : Aqi.fromPm10(pm10);
      final aqi = math.max(a25, a10);
      // Nearest hotspot within range gives the likely cause.
      Map<String, Object?>? cause;
      var best = double.infinity;
      for (final h in spots) {
        final at = h['at']! as List;
        final d = Geo.distanceM(
          GeoPoint(lat: lat, lon: lon),
          GeoPoint(lat: (at[1] as num).toDouble(), lon: (at[0] as num).toDouble()),
        );
        if (d < best && d <= causeRadiusM) {
          best = d;
          cause = h;
        }
      }
      final ward = c['ward'] as String?;
      features.add({
        'type': 'Feature',
        'id': c['cell_id'],
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [lon - dLon, lat - dLat],
              [lon + dLon, lat - dLat],
              [lon + dLon, lat + dLat],
              [lon - dLon, lat + dLat],
              [lon - dLon, lat - dLat],
            ],
          ],
        },
        'properties': {
          'cell_id': c['cell_id'],
          'pm25': ?pm25,
          'pm10': ?pm10,
          'confidence': (c['confidence'] as num?)?.toDouble() ?? 0.5,
          'aqi': aqi,
          'aqi_category': Aqi.category(aqi).wire,
          'dominant_pollutant': a10 > a25 ? 'pm10' : 'pm25',
          'cause_label': (cause?['cause'] as String?)?.toLowerCase() ?? 'unknown',
          if (cause != null) 'cause_conf': (cause['causeConf'] as num?)?.toDouble() ?? 0.5,
          if (ward != null) 'place_name': {'en': ward, 'hi': ward},
          'is_simulated': simulated,
        },
      });
    }
    return {
      'type': 'FeatureCollection',
      'as_of': twin['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
      'resolution_m': 500,
      'aqi_basis': 'indicative_hourly',
      'licence': {'data': 'CC-BY-4.0', 'attribution': 'HawaCommand AI-ML digital twin'},
      'features': features,
    };
  }
}
