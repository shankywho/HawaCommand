import 'dart:math' as math;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo.freezed.dart';
part 'geo.g.dart';

/// WGS84 point. GeoJSON order on the wire is `[lon, lat]` (CONTRACTS §1).
@freezed
abstract class GeoPoint with _$GeoPoint {
  const factory GeoPoint({required double lat, required double lon}) = _GeoPoint;

  const GeoPoint._();

  factory GeoPoint.fromJson(Map<String, Object?> json) => _$GeoPointFromJson(json);

  /// From GeoJSON `coordinates` (`[lon, lat]`).
  factory GeoPoint.fromLonLat(List<double> coordinates) =>
      GeoPoint(lat: coordinates[1], lon: coordinates[0]);

  List<double> toLonLat() => [lon, lat];
}

/// Axis-aligned box `[minLon, minLat, maxLon, maxLat]`.
@freezed
abstract class GeoBox with _$GeoBox {
  const factory GeoBox({
    required double minLon,
    required double minLat,
    required double maxLon,
    required double maxLat,
  }) = _GeoBox;

  const GeoBox._();

  factory GeoBox.fromJson(Map<String, Object?> json) => _$GeoBoxFromJson(json);

  String toQuery() => [minLon, minLat, maxLon, maxLat].map((v) => v.toStringAsFixed(4)).join(',');

  GeoPoint get center => GeoPoint(lat: (minLat + maxLat) / 2, lon: (minLon + maxLon) / 2);
}

abstract final class Geo {
  static const _earthRadiusM = 6371008.8;

  /// Great-circle distance in metres.
  static double distanceM(GeoPoint a, GeoPoint b) {
    final dLat = _rad(b.lat - a.lat);
    final dLon = _rad(b.lon - a.lon);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(a.lat)) * math.cos(_rad(b.lat)) * math.pow(math.sin(dLon / 2), 2);
    return 2 * _earthRadiusM * math.asin(math.min(1, math.sqrt(h)));
  }

  /// A box around [p] snapped to a ~1 km grid (0.01°), so the precise position never leaves
  /// the phone (SCREENS C1). The box covers the snapped cell plus one cell on each side.
  static GeoBox snappedBox(GeoPoint p, {double step = 0.01, int pad = 1}) {
    double floorTo(double v) => (v / step).floor() * step;
    final lat0 = floorTo(p.lat);
    final lon0 = floorTo(p.lon);
    return GeoBox(
      minLon: _round4(lon0 - pad * step),
      minLat: _round4(lat0 - pad * step),
      maxLon: _round4(lon0 + (pad + 1) * step),
      maxLat: _round4(lat0 + (pad + 1) * step),
    );
  }

  /// Ray-casting point-in-polygon on an outer ring of `[lon, lat]` pairs.
  static bool contains(List<List<double>> ring, GeoPoint p) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];
      final crosses =
          (yi > p.lat) != (yj > p.lat) && p.lon < (xj - xi) * (p.lat - yi) / (yj - yi) + xi;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  /// Mean of the ring's vertices (good enough for 1 km cells).
  static GeoPoint ringCenter(List<List<double>> ring) {
    final pts = ring.length > 1 && ring.first[0] == ring.last[0] && ring.first[1] == ring.last[1]
        ? ring.sublist(0, ring.length - 1)
        : ring;
    var lat = 0.0;
    var lon = 0.0;
    for (final c in pts) {
      lon += c[0];
      lat += c[1];
    }
    return GeoPoint(lat: lat / pts.length, lon: lon / pts.length);
  }

  /// Rounds to 0.005° (~500 m) for the citizen alert home (SCREENS C2).
  static GeoPoint coarse(GeoPoint p, {double step = 0.005}) => GeoPoint(
    lat: _round4((p.lat / step).round() * step),
    lon: _round4((p.lon / step).round() * step),
  );

  static double _rad(double deg) => deg * math.pi / 180;

  static double _round4(double v) => (v * 10000).round() / 10000;
}
