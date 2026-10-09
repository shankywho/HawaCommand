import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Approximate coordinates for Delhi places named in routes and reports.
///
/// The backend's `/v1/driver/route` stops carry names but no coordinates, so
/// the app resolves them here for the mini-map and distance estimates.
abstract final class Gazetteer {
  static const _places = <String, LatLng>{
    'anand vihar isbt': LatLng(28.6469, 77.3159),
    'anand vihar': LatLng(28.6452, 77.3121),
    'patparganj': LatLng(28.6275, 77.3050),
    'ghazipur': LatLng(28.6250, 77.3290),
    'shahdara': LatLng(28.6730, 77.2890),
    'mundka': LatLng(28.6823, 77.0305),
    'udyog nagar': LatLng(28.6817, 77.0540),
    'rohtak road': LatLng(28.6817, 77.0540),
    'nangloi': LatLng(28.6790, 77.0660),
    'bawana': LatLng(28.7760, 77.0510),
    'wazirpur': LatLng(28.7000, 77.1650),
    'jahangirpuri': LatLng(28.7330, 77.1710),
    'punjabi bagh': LatLng(28.6740, 77.1310),
    'okhla': LatLng(28.5310, 77.2710),
    'ito': LatLng(28.6290, 77.2410),
  };

  static const delhi = LatLng(28.6390, 77.2200);

  /// Longest matching key wins, so "anand vihar isbt" beats "anand vihar".
  static LatLng? lookup(String name) {
    final lower = name.toLowerCase();
    LatLng? best;
    var bestLen = 0;
    for (final entry in _places.entries) {
      if (lower.contains(entry.key) && entry.key.length > bestLen) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    return best;
  }
}

/// Hindi spelling of hotspot place names from `/v1/hotspots`.
String placeNameHi(String place) =>
    const {
      'Ghazipur': 'गाज़ीपुर',
      'Anand Vihar': 'आनंद विहार',
      'Shahdara': 'शाहदरा',
      'ITO': 'आईटीओ',
      'Wazirpur': 'वज़ीरपुर',
      'Bawana': 'बवाना',
      'Mundka': 'मुंडका',
      'Jahangirpuri': 'जहाँगीरपुरी',
      'Okhla': 'ओखला',
      'Punjabi Bagh': 'पंजाबी बाग',
    }[place] ??
    place;

/// Great-circle distance in kilometres.
double distanceKm(LatLng a, LatLng b) => const Distance().as(LengthUnit.Meter, a, b) / 1000;

String formatKm(double km) => km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

/// Mean of a set of points (fine at city scale).
LatLng centroid(Iterable<LatLng> points) {
  var lat = 0.0;
  var lon = 0.0;
  var n = 0;
  for (final p in points) {
    lat += p.latitude;
    lon += p.longitude;
    n++;
  }
  if (n == 0) return Gazetteer.delhi;
  return LatLng(lat / n, lon / n);
}

/// Vertices of a flat-top hexagon of [radiusKm] around [center].
List<LatLng> hexagon(LatLng center, double radiusKm) {
  const kmPerDegLat = 110.574;
  final kmPerDegLon = 111.320 * math.cos(center.latitude * math.pi / 180);
  return List.generate(6, (i) {
    final angle = math.pi / 3 * i;
    return LatLng(
      center.latitude + radiusKm * math.sin(angle) / kmPerDegLat,
      center.longitude + radiusKm * math.cos(angle) / kmPerDegLon,
    );
  });
}

/// Centres of a flat-top hex grid covering the box around [center].
List<LatLng> hexGrid(
  LatLng center, {
  required double radiusKm,
  required int cols,
  required int rows,
}) {
  const kmPerDegLat = 110.574;
  final kmPerDegLon = 111.320 * math.cos(center.latitude * math.pi / 180);
  final dx = radiusKm * 1.5;
  final dy = radiusKm * math.sqrt(3);
  final cells = <LatLng>[];
  for (var c = -cols; c <= cols; c++) {
    for (var r = -rows; r <= rows; r++) {
      final offsetY = c.isOdd ? dy / 2 : 0.0;
      cells.add(
        LatLng(
          center.latitude + (r * dy + offsetY) / kmPerDegLat,
          center.longitude + (c * dx) / kmPerDegLon,
        ),
      );
    }
  }
  return cells;
}
