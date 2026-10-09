import 'dart:math' as math;

import 'package:hawa_app/core/utils/geo.dart';

/// Douglas–Peucker simplification (ARCHITECTURE §12.3: 5 m tolerance at z15). Pure.
List<GeoPoint> simplifyPolyline(List<GeoPoint> points, {double toleranceM = 5}) {
  if (points.length <= 2) return List.of(points);
  final keep = List<bool>.filled(points.length, false);
  keep[0] = true;
  keep[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final (start, end) = stack.removeLast();
    var maxD = 0.0;
    var index = -1;
    for (var i = start + 1; i < end; i++) {
      final d = _perpendicularM(points[i], points[start], points[end]);
      if (d > maxD) {
        maxD = d;
        index = i;
      }
    }
    if (index != -1 && maxD > toleranceM) {
      keep[index] = true;
      stack
        ..add((start, index))
        ..add((index, end));
    }
  }
  return [
    for (var i = 0; i < points.length; i++)
      if (keep[i]) points[i],
  ];
}

/// Distance in metres from [p] to the segment [a]–[b] on a local equirectangular projection.
double _perpendicularM(GeoPoint p, GeoPoint a, GeoPoint b) {
  const mPerDegLat = 110574.0;
  final mPerDegLon = 111320.0 * math.cos(a.lat * math.pi / 180);
  const ax = 0.0;
  const ay = 0.0;
  final bx = (b.lon - a.lon) * mPerDegLon;
  final by = (b.lat - a.lat) * mPerDegLat;
  final px = (p.lon - a.lon) * mPerDegLon;
  final py = (p.lat - a.lat) * mPerDegLat;
  final dx = bx - ax;
  final dy = by - ay;
  final len2 = dx * dx + dy * dy;
  if (len2 == 0) return math.sqrt(px * px + py * py);
  final t = ((px - ax) * dx + (py - ay) * dy) / len2;
  final tc = t.clamp(0.0, 1.0);
  final cx = ax + tc * dx;
  final cy = ay + tc * dy;
  return math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy));
}
