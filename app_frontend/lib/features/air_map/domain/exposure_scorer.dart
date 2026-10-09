import 'dart:math' as math;

import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/air_map/domain/route_option.dart';
import 'package:hawa_app/features/air_map/domain/travel_mode.dart';

/// PM2.5 (µg/m³) at a point, [hoursAhead] from now; null where the model has no data.
typedef PmField = double? Function(GeoPoint point, double hoursAhead);

/// P10/P90 relative to P50 at [hoursAhead] (dose uncertainty band).
typedef BandFn = (double low, double high) Function(double hoursAhead);

/// Scores routes by the PM2.5 a traveller would inhale on them (pure Dart, unit tested).
///
/// The route is walked in ≤ 100 m steps. At each step the time on the road is known, so the ML
/// field is read at the hour the traveller actually passes there, not just "now".
abstract final class ExposureScorer {
  static const sampleStepM = 100.0;

  /// PM2.5 above which air is very poor or severe (CPCB).
  static const redZonePm25 = 120.0;

  /// Longest coloured run of the route line, so the colour follows the air street by street.
  static const runMaxM = 400.0;

  static RouteExposure score({
    required List<GeoPoint> geometry,
    required double durationS,
    required PmField field,
    required TravelMode mode,
    List<double>? segmentDurationsS,
    double departureHoursAhead = 0,
    BandFn? band,
  }) {
    final n = geometry.length;
    if (n < 2 || durationS <= 0) {
      return const RouteExposure(
        avgPm25: 0,
        maxPm25: 0,
        doseUg: 0,
        doseLowUg: 0,
        doseHighUg: 0,
        redZoneMinutes: 0,
        runs: [],
        coverage: 0,
      );
    }
    final lengths = [for (var i = 0; i < n - 1; i++) Geo.distanceM(geometry[i], geometry[i + 1])];
    final total = lengths.fold<double>(0, (a, b) => a + b);
    final durations = segmentDurationsS != null && segmentDurationsS.length == n - 1
        ? segmentDurationsS
        : [for (final l in lengths) total == 0 ? durationS / (n - 1) : durationS * l / total];

    final rate = mode.breathingM3h * mode.infiltration / 3600; // m³ of outdoor-equivalent air per s
    var t = 0.0;
    var covered = 0.0;
    var missing = 0.0;
    var pmTime = 0.0;
    var dose = 0.0;
    var doseLow = 0.0;
    var doseHigh = 0.0;
    var red = 0.0;
    var maxPm = 0.0;
    final runs = <ExposureRun>[];
    var runPoints = <GeoPoint>[geometry.first];
    AqiCategory? runCategory;
    var runPm = 0.0;
    var runN = 0;
    var runLength = 0.0;

    for (var i = 0; i < n - 1; i++) {
      final a = geometry[i];
      final b = geometry[i + 1];
      final k = math.max(1, (lengths[i] / sampleStepM).ceil());
      final dt = durations[i] / k;
      var segPm = 0.0;
      var segN = 0;
      for (var j = 0; j < k; j++) {
        final f = (j + 0.5) / k;
        final p = GeoPoint(lat: a.lat + (b.lat - a.lat) * f, lon: a.lon + (b.lon - a.lon) * f);
        final hours = departureHoursAhead + (t + dt * (j + 0.5)) / 3600;
        final pm = field(p, hours);
        if (pm == null) {
          missing += dt;
          continue;
        }
        final (lo, hi) = band?.call(hours) ?? (1.0, 1.0);
        covered += dt;
        pmTime += pm * dt;
        dose += pm * rate * dt;
        doseLow += pm * lo * rate * dt;
        doseHigh += pm * hi * rate * dt;
        if (pm > redZonePm25) red += dt;
        maxPm = math.max(maxPm, pm);
        segPm += pm;
        segN++;
      }
      t += durations[i];

      final cat = segN == 0 ? AqiCategory.unknown : Aqi.category(Aqi.fromPm25(segPm / segN));
      if (runCategory != null && (cat != runCategory || runLength >= runMaxM)) {
        runs.add(
          ExposureRun(
            points: runPoints,
            category: runCategory,
            avgPm25: runN == 0 ? 0 : runPm / runN,
          ),
        );
        runPoints = [a];
        runPm = 0;
        runN = 0;
        runLength = 0;
      }
      runCategory = cat;
      runPoints.add(b);
      runPm += segPm;
      runN += segN;
      runLength += lengths[i];
    }
    if (runPoints.length > 1) {
      runs.add(
        ExposureRun(
          points: runPoints,
          category: runCategory ?? AqiCategory.unknown,
          avgPm25: runN == 0 ? 0 : runPm / runN,
        ),
      );
    }

    final avg = covered == 0 ? 0.0 : pmTime / covered;
    // Stretches outside the model take the route's mean, so short gaps do not flatter a route.
    final gap = avg * rate * missing;
    return RouteExposure(
      avgPm25: avg,
      maxPm25: maxPm,
      doseUg: dose + gap,
      doseLowUg: doseLow + gap,
      doseHighUg: doseHigh + gap,
      redZoneMinutes: red / 60,
      runs: runs,
      coverage: covered + missing == 0 ? 0 : covered / (covered + missing),
    );
  }

  /// Weight of extra travel time against dose when picking the recommended route: a route that
  /// takes 20 % longer must cut the dose by more than 10 % to win.
  static const timeWeight = 0.5;

  /// Tags fastest, cleanest air (lowest average PM2.5) and recommended (least dose for the time)
  /// and sorts recommended first, then by score.
  static List<RouteOption> rank(List<RouteOption> options) {
    if (options.isEmpty) return options;
    final fastest = options.reduce((a, b) => a.durationS <= b.durationS ? a : b);
    final cleanest = options.reduce((a, b) => a.exposure.avgPm25 <= b.exposure.avgPm25 ? a : b);
    double scoreOf(RouteOption o) {
      final doseRatio = fastest.exposure.doseUg <= 0
          ? 1.0
          : o.exposure.doseUg / fastest.exposure.doseUg;
      final extra = fastest.durationS <= 0
          ? 0.0
          : math.max(0, (o.durationS - fastest.durationS) / fastest.durationS);
      return doseRatio + timeWeight * extra;
    }

    final sorted = [...options]..sort((a, b) => scoreOf(a).compareTo(scoreOf(b)));
    final recommended = sorted.first;
    return [
      for (final o in sorted)
        o.withTags({
          if (identical(o, recommended)) RouteTag.recommended,
          if (identical(o, cleanest)) RouteTag.cleanest,
          if (identical(o, fastest)) RouteTag.fastest,
        }),
    ];
  }

  /// Drops near-duplicates (same length and time within 2 %), keeping the first.
  static List<T> dedupe<T>(
    List<T> routes,
    double Function(T) distance,
    double Function(T) duration,
  ) {
    final out = <T>[];
    for (final r in routes) {
      final dup = out.any((o) {
        final dd = (distance(o) - distance(r)).abs() / math.max(1, distance(o));
        final dt = (duration(o) - duration(r)).abs() / math.max(1, duration(o));
        return dd < 0.02 && dt < 0.02;
      });
      if (!dup) out.add(r);
    }
    return out;
  }
}
