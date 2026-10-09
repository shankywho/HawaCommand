import 'package:hawa_app/app/router/deep_links.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/features/alerts/data/alerts_repository_impl.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alert_detail_controller.g.dart';

/// One alert from the inbox cache. When it is not cached yet (opened from a deep link) it is
/// fetched with `GET /v1/alerts/{id}` first; a failure surfaces as an error with retry.
/// Opening it marks it read locally (SCREENS X2).
@riverpod
Stream<AppAlert?> alertDetail(Ref ref, String alertId) async* {
  final repo = ref.watch(alertsRepositoryProvider);
  final cached = await repo.watchAlert(alertId).first;
  if (cached == null) await repo.fetch(alertId);
  await repo.markRead(alertId);
  yield* repo.watchAlert(alertId);
}

/// The app route the alert's `deep_link` opens for the active role, or null when the link is
/// not allow-listed, belongs to a role that is not active, or points back at this alert.
@riverpod
String? alertRelatedRoute(Ref ref, String alertId, String? deepLink) {
  if (deepLink == null || deepLink.isEmpty) return null;
  final active = ref.watch(activeRoleWireProvider);
  final roles = ref.watch(currentUserProvider)?.roles ?? const <String>[];
  final target = resolveDeepLink(deepLink, activeRole: active, roles: roles);
  if (target == null || target.role != active || target.route == Routes.alert(alertId)) {
    return null;
  }
  return target.route;
}

/// Acknowledge ("I've read this"): one local write + one `alert_ack` outbox op. State is busy.
@riverpod
class AlertAckController extends _$AlertAckController {
  @override
  bool build(String alertId) => false;

  Future<void> acknowledge() async {
    if (state) return;
    state = true;
    try {
      await ref.read(alertsRepositoryProvider).acknowledge(alertId);
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
