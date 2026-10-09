import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/driver_route/domain/route_diff.dart';
import 'package:hawa_app/features/driver_route/domain/shift.dart';
import 'package:hawa_app/features/driver_route/domain/skip_reason.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';

/// Driver route: cache-first reads and outbox writes (Flow B).
abstract interface class DriverRouteRepository {
  /// Today's route from drift (the UI's source of truth). Null when nothing is cached.
  Stream<TodayRoute?> watchRoute(String date);

  /// `GET /v1/tasks/mine?date=` → drift. Returns what changed against the cached version.
  Future<RouteDiff?> refresh(String date);

  /// `task_ack` for every dispatched stop (one per task; dedupe).
  Future<void> acknowledgeDispatched(TodayRoute route);

  /// `task_status en_route` (before the Google Maps hand-off).
  Future<void> markEnRoute(Stop stop);

  /// Local "arrived" only: the server sets `in_progress` on `spray.started`.
  Future<void> markArrived(String taskId, {required DateTime at});

  Future<void> skip(Stop stop, SkipReason reason, {String? note});

  /// HawaTag offline fallback: optional photo upload, then `task_status done` with
  /// `source=manual` (lower evidence).
  Future<void> manualDone(Stop stop, {double? litres, String? photoPath, GeoPoint? location});

  Future<void> startShift(Shift shift, {GeoPoint? location});

  Future<void> endShift(Shift shift);
}
