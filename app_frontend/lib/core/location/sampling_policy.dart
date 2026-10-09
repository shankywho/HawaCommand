import 'package:flutter/foundation.dart' show immutable;

/// Accuracy tiers mapped to geolocator's `LocationAccuracy` by the tracker.
enum SamplingAccuracy { high, medium, low }

@immutable
class SamplingPolicy {
  const SamplingPolicy({
    required this.accuracy,
    required this.distanceFilterM,
    required this.interval,
  });

  final SamplingAccuracy accuracy;
  final int distanceFilterM;
  final Duration interval;

  @override
  bool operator ==(Object other) =>
      other is SamplingPolicy &&
      other.accuracy == accuracy &&
      other.distanceFilterM == distanceFilterM &&
      other.interval == interval;

  @override
  int get hashCode => Object.hash(accuracy, distanceFilterM, interval);

  @override
  String toString() =>
      'SamplingPolicy(${accuracy.name}, ${distanceFilterM}m, ${interval.inSeconds}s)';
}

/// Battery- and proximity-aware sampling (ARCHITECTURE §11.2). Pure, unit tested.
SamplingPolicy choosePolicy({
  required double? distanceToNextStopM,
  required Duration stationaryFor,
  required int? batteryLevel,
  required bool charging,
}) {
  final near = distanceToNextStopM != null && distanceToNextStopM <= 500;
  final lowBattery = batteryLevel != null && batteryLevel < 20 && !charging;
  if (lowBattery) {
    return near
        ? const SamplingPolicy(
            accuracy: SamplingAccuracy.low,
            distanceFilterM: 15,
            interval: Duration(seconds: 10),
          )
        : const SamplingPolicy(
            accuracy: SamplingAccuracy.low,
            distanceFilterM: 100,
            interval: Duration(seconds: 60),
          );
  }
  if (near) {
    return const SamplingPolicy(
      accuracy: SamplingAccuracy.high,
      distanceFilterM: 15,
      interval: Duration(seconds: 5),
    );
  }
  if (stationaryFor >= const Duration(minutes: 2)) {
    return const SamplingPolicy(
      accuracy: SamplingAccuracy.medium,
      distanceFilterM: 50,
      interval: Duration(seconds: 60),
    );
  }
  return const SamplingPolicy(
    accuracy: SamplingAccuracy.medium,
    distanceFilterM: 50,
    interval: Duration(seconds: 15),
  );
}
