import 'package:hawa_app/features/air_map/domain/exposure_scorer.dart';
import 'package:hawa_app/features/air_map/domain/route_option.dart';
import 'package:hawa_app/features/air_map/domain/travel_mode.dart';

class DepartureOption {
  const DepartureOption({required this.hoursAhead, required this.doseUg, required this.avgPm25});

  final int hoursAhead;
  final double doseUg;
  final double avgPm25;
}

/// "Leave later, breathe less": re-scores one route for departures over the next hours using the
/// forecast-scaled field (pure Dart, unit tested).
abstract final class DeparturePlanner {
  static List<DepartureOption> options({
    required RouteOption route,
    required PmField field,
    required TravelMode mode,
    int hours = 6,
  }) => [
    for (var h = 0; h <= hours; h++)
      () {
        final e = ExposureScorer.score(
          geometry: route.geometry,
          durationS: route.durationS,
          field: field,
          mode: mode,
          departureHoursAhead: h.toDouble(),
        );
        return DepartureOption(hoursAhead: h, doseUg: e.doseUg, avgPm25: e.avgPm25);
      }(),
  ];

  /// The best later departure if it saves at least [minSaving] of the dose versus leaving now.
  static DepartureOption? best(List<DepartureOption> options, {double minSaving = 0.1}) {
    if (options.length < 2) return null;
    final now = options.first;
    final best = options.reduce((a, b) => a.doseUg <= b.doseUg ? a : b);
    if (best.hoursAhead == 0 || now.doseUg <= 0) return null;
    return best.doseUg <= now.doseUg * (1 - minSaving) ? best : null;
  }
}
