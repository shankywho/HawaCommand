import 'dart:math' as math;

import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/exposure_scorer.dart';

/// Proposes clean-air detour waypoints for the road router (pure Dart, unit tested).
///
/// Public routers return at most one or two alternatives, all optimised for time. This finds the
/// dirtiest stretch of the fastest route (or the nearest ML hotspot), then looks sideways for
/// cleaner air in the twin field. The router is then asked for a route through that point.
abstract final class DetourPlanner {
  static const _sampleM = 200.0;
  static const _windowM = 600.0;
  static const _offsetsM = [1200.0, 2200.0, 3500.0];

  static List<GeoPoint> viaPoints({
    required List<GeoPoint> route,
    required PmField field,
    List<Hotspot> hotspots = const [],
    int max = 2,
  }) {
    final samples = _resample(route, _sampleM);
    if (samples.length < 8) return const []; // < ~1.5 km: no meaningful detour
    final values = [for (final s in samples) field(s, 0)];
    final half = (_windowM / _sampleM).round();
    final skip = math.max(2, (samples.length * 0.12).round()); // keep clear of the two ends

    // The worst window along the route.
    var worst = -1;
    var worstAvg = -1.0;
    for (var i = skip; i < samples.length - skip; i++) {
      var s = 0.0;
      var c = 0;
      for (var j = math.max(0, i - half); j <= math.min(samples.length - 1, i + half); j++) {
        final v = values[j];
        if (v != null) {
          s += v;
          c++;
        }
      }
      if (c > 0 && s / c > worstAvg) {
        worstAvg = s / c;
        worst = i;
      }
    }
    if (worst < 0) return const [];

    // A hotspot close to the route wins: steer away from it.
    GeoPoint? away;
    var bestHot = double.negativeInfinity;
    for (final h in hotspots) {
      var nearest = -1;
      var nearestD = double.infinity;
      for (var i = skip; i < samples.length - skip; i++) {
        final d = Geo.distanceM(samples[i], h.location);
        if (d < nearestD) {
          nearestD = d;
          nearest = i;
        }
      }
      if (nearest >= 0 && nearestD < 1500 && h.pm25 > bestHot) {
        bestHot = h.pm25;
        worst = nearest;
        away = h.location;
      }
    }

    final p = samples[worst];
    final prev = samples[math.max(0, worst - 1)];
    final next = samples[math.min(samples.length - 1, worst + 1)];
    final (dx, dy) = _metres(prev, next);
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return const [];
    // Unit normal to the route direction.
    final nx = -dy / len;
    final ny = dx / len;

    final candidates = <(GeoPoint, double, int)>[];
    for (final side in const [1, -1]) {
      (GeoPoint, double)? best;
      for (final off in _offsetsM) {
        final c = _offset(p, nx * off * side, ny * off * side);
        final score = _neighbourhood(c, field);
        if (score == null) continue;
        if (best == null || score < best.$2) best = (c, score);
      }
      if (best != null && best.$2 < worstAvg * 0.97) candidates.add((best.$1, best.$2, side));
    }
    if (away != null) {
      // Prefer the side facing away from the hotspot.
      final (hx, hy) = _metres(away, p);
      final awaySide = (hx * nx + hy * ny) >= 0 ? 1 : -1;
      candidates.sort((a, b) {
        if (a.$3 == awaySide && b.$3 != awaySide) return -1;
        if (b.$3 == awaySide && a.$3 != awaySide) return 1;
        return a.$2.compareTo(b.$2);
      });
    } else {
      candidates.sort((a, b) => a.$2.compareTo(b.$2));
    }
    return [for (final c in candidates.take(max)) c.$1];
  }

  static double? _neighbourhood(GeoPoint c, PmField field) {
    var s = 0.0;
    var n = 0;
    for (final (e, nn) in const [
      (0.0, 0.0),
      (400.0, 0.0),
      (-400.0, 0.0),
      (0.0, 400.0),
      (0.0, -400.0),
    ]) {
      final v = field(_offset(c, e, nn), 0);
      if (v != null) {
        s += v;
        n++;
      }
    }
    return n < 3 ? null : s / n;
  }

  /// Points every [stepM] metres along [line].
  static List<GeoPoint> _resample(List<GeoPoint> line, double stepM) {
    if (line.length < 2) return line;
    final out = <GeoPoint>[line.first];
    var carry = 0.0;
    for (var i = 0; i < line.length - 1; i++) {
      final a = line[i];
      final b = line[i + 1];
      final d = Geo.distanceM(a, b);
      if (d == 0) continue;
      var pos = stepM - carry;
      while (pos <= d) {
        final f = pos / d;
        out.add(GeoPoint(lat: a.lat + (b.lat - a.lat) * f, lon: a.lon + (b.lon - a.lon) * f));
        pos += stepM;
      }
      carry = d - (pos - stepM);
    }
    if (out.last != line.last) out.add(line.last);
    return out;
  }

  /// East/north metres from [a] to [b] (local flat approximation).
  static (double, double) _metres(GeoPoint a, GeoPoint b) {
    final kx = 111320 * math.cos(a.lat * math.pi / 180);
    return ((b.lon - a.lon) * kx, (b.lat - a.lat) * 110540);
  }

  static GeoPoint _offset(GeoPoint p, double eastM, double northM) {
    final kx = 111320 * math.cos(p.lat * math.pi / 180);
    return GeoPoint(lat: p.lat + northM / 110540, lon: p.lon + eastM / kx);
  }
}
