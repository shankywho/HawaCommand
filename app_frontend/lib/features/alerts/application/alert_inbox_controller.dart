import 'dart:async';

import 'package:hawa_app/core/sync/stale_policy.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/alerts/data/alerts_repository_impl.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alert_inbox_controller.g.dart';

/// Inbox freshness threshold (OFFLINE_AND_SYNC §2).
const Duration alertsStaleAfter = StalePolicy.alerts;

/// The last refresh outcome (stale-while-revalidate: the list itself comes from drift).
class RefreshStatus {
  const RefreshStatus({this.busy = false, this.error});

  final bool busy;

  /// The last refresh failure, cleared by the next success.
  final Object? error;
}

/// The signed-in user's active role wire value (for acknowledge and the audience filter).
@riverpod
String? alertsActiveRole(Ref ref) => ref.watch(activeRoleWireProvider);

/// The current instant (server-independent device clock; used to grey expired alerts).
@riverpod
DateTime alertsNow(Ref ref) => ref.watch(appClockProvider).now().toUtc();

/// Inbox rows, newest first. Rows for another role's audience are hidden after a role switch;
/// rows without an audience (stored from a push) are always shown.
@riverpod
Stream<List<AppAlert>> alertInbox(Ref ref) {
  final role = ref.watch(alertsActiveRoleProvider);
  return ref
      .watch(alertsRepositoryProvider)
      .watchInbox()
      .map(
        (all) => [
          for (final a in all)
            if (role == null || a.audience.isEmpty || a.audience == role) a,
        ],
      );
}

/// Last successful `GET /v1/alerts`.
@riverpod
Stream<DateTime?> alertsLastSuccess(Ref ref) =>
    ref.watch(alertsRepositoryProvider).watchLastSuccess();

/// Refreshes the inbox on open, on every sync trigger and on pull-to-refresh.
@riverpod
class AlertInboxController extends _$AlertInboxController {
  @override
  RefreshStatus build() {
    ref.listen(syncTriggersProvider, (_, _) => unawaited(refresh()));
    unawaited(Future.microtask(refresh));
    return const RefreshStatus(busy: true);
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    state = RefreshStatus(busy: true, error: state.error);
    try {
      await ref.read(alertsRepositoryProvider).refresh();
      if (ref.mounted) state = const RefreshStatus();
    } on Object catch (e) {
      if (ref.mounted) state = RefreshStatus(error: e);
    }
  }
}
