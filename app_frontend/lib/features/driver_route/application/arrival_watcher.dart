import 'dart:async';

import 'package:hawa_app/core/location/geofence.dart';
import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/location/shift_location_tracker.dart';
import 'package:hawa_app/features/driver_route/data/driver_route_repository_impl.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'arrival_watcher.g.dart';

/// Geofence (150 m, 20 s dwell) on the next stop during a shift → local "arrived" only
/// (ARCHITECTURE §11.3). Also steers the tracker's sampling by distance to the next stop.
class ArrivalWatcher {
  ArrivalWatcher({required this.tracker, required this.onArrived});

  final ShiftLocationTracker tracker;
  final Future<void> Function(String taskId, DateTime at) onArrived;
  final _detector = ArrivalDetector();
  StreamSubscription<LocationFix>? _sub;
  TodayRoute? _route;

  void start() {
    _sub ??= tracker.positions.listen(_onFix);
  }

  void updateRoute(TodayRoute? route) {
    _route = route;
    tracker.setNextStop(route?.nextStop?.location);
  }

  Future<void> _onFix(LocationFix fix) async {
    final next = _route?.nextStop;
    if (next == null || next.arrivedAt != null) return;
    final arrived = ArrivalDetector(radiusM: next.arrivalRadiusM, dwell: _detector.dwell);
    // One detector keeps the dwell timer; the radius comes from the stop.
    final hit = (next.arrivalRadiusM == _detector.radiusM ? _detector : arrived).feed(
      targetId: next.taskId,
      target: next.location,
      position: fix.point,
      at: fix.at,
    );
    if (hit) await onArrived(next.taskId, fix.at);
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _detector.reset();
  }
}

@Riverpod(keepAlive: true)
ArrivalWatcher arrivalWatcher(Ref ref) {
  final watcher = ArrivalWatcher(
    tracker: ref.watch(shiftLocationTrackerProvider),
    onArrived: (id, at) => ref.read(driverRouteRepositoryProvider).markArrived(id, at: at),
  );
  ref.onDispose(() => unawaited(watcher.stop()));
  return watcher;
}
