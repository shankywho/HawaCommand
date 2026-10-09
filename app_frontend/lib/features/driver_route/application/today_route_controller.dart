import 'dart:async';

import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/features/driver_route/application/route_change_detector.dart';
import 'package:hawa_app/features/driver_route/data/driver_route_repository_impl.dart';
import 'package:hawa_app/features/driver_route/data/task_event_applier.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_route_controller.g.dart';

/// Freshness of one scope for the offline/stale banners (OFFLINE_AND_SYNC §9).
class Freshness {
  const Freshness({this.lastSuccess, this.error});

  final DateTime? lastSuccess;
  final Object? error;
}

/// Today's route: the drift stream is the source of truth; refresh is stale-while-revalidate and
/// runs on build, on every sync trigger and when the server signals a route change.
@riverpod
class TodayRouteController extends _$TodayRouteController {
  bool _acked = false;

  @override
  Stream<TodayRoute?> build() {
    final date = ref.watch(serviceDateProvider);
    final repo = ref.watch(driverRouteRepositoryProvider);
    ref.listen(syncTriggersProvider, (_, _) => unawaited(refresh()));
    final sub = ref.read(taskEventApplierProvider).routeChanged.listen((_) => unawaited(refresh()));
    ref.onDispose(sub.cancel);
    unawaited(Future.microtask(refresh));
    return repo.watchRoute(date);
  }

  Future<void> refresh() async {
    final date = ref.read(serviceDateProvider);
    final repo = ref.read(driverRouteRepositoryProvider);
    try {
      final diff = await repo.refresh(date);
      if (!ref.mounted) return;
      ref.read(routeRefreshErrorProvider.notifier).set(null);
      if (diff != null && !diff.isEmpty) ref.read(routeChangeNoticeProvider.notifier).show(diff);
      final route = await repo.watchRoute(date).first;
      if (route != null && !_acked) {
        _acked = true;
        // Opening the route acknowledges dispatched stops (SCREENS D1).
        await repo.acknowledgeDispatched(route);
      }
    } on Failure catch (f) {
      if (ref.mounted) ref.read(routeRefreshErrorProvider.notifier).set(f);
    }
  }
}

/// The last refresh failure (cleared on success): the banner over cached data.
@Riverpod(keepAlive: true)
class RouteRefreshError extends _$RouteRefreshError {
  @override
  Failure? build() => null;

  // A notifier command (`ref.read(p.notifier).set(…)`) reads better than a setter here.
  // ignore: use_setters_to_change_properties
  void set(Failure? f) => state = f;
}

/// Last successful refresh of today's route.
@riverpod
Stream<Freshness> routeFreshness(Ref ref) {
  final date = ref.watch(serviceDateProvider);
  final error = ref.watch(routeRefreshErrorProvider);
  return ref
      .watch(appDatabaseProvider)
      .syncStateDao
      .watch(DriverRouteRepositoryImpl.scope(date))
      .map((row) => Freshness(lastSuccess: row?.lastSuccessAt, error: error));
}
