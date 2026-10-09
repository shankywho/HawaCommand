import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/driver_route/data/driver_route_repository_impl.dart';
import 'package:hawa_app/features/driver_route/domain/skip_reason.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stop_actions_controller.g.dart';

/// One stop, live from drift (D3).
@riverpod
Stream<Stop?> stopDetail(Ref ref, String taskId) =>
    ref.watch(taskLocalSourceProvider).watchStop(taskId);

/// Stop actions (D3–D5). The driver never posts `in_progress`: arrival is local only; the server
/// sets `in_progress` on HawaTag `spray_start` (backend ARCHITECTURE §5.2).
@riverpod
class StopActions extends _$StopActions {
  @override
  void build() {}

  /// `task_status en_route`, before the Google Maps hand-off.
  Future<void> navigate(Stop stop) => ref.read(driverRouteRepositoryProvider).markEnRoute(stop);

  Future<void> arrived(Stop stop) => ref
      .read(driverRouteRepositoryProvider)
      .markArrived(stop.taskId, at: ref.read(appClockProvider).now());

  Future<void> skip(Stop stop, SkipReason reason, {String? note}) =>
      ref.read(driverRouteRepositoryProvider).skip(stop, reason, note: note);

  Future<void> manualDone(Stop stop, {double? litres, String? photoPath}) async {
    final fix = await ref
        .read(locationServiceProvider)
        .currentFix(timeout: const Duration(seconds: 8));
    await ref
        .read(driverRouteRepositoryProvider)
        .manualDone(stop, litres: litres, photoPath: photoPath, location: fix?.point);
  }
}
