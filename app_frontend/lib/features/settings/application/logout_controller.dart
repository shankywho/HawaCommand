import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logout_controller.g.dart';

/// Logout (OFFLINE_AND_SYNC §10): unsent ops → warn, "Send now" drains with a 20 s budget,
/// "Log out anyway" wipes. Kept alive: the More sheet that starts the flow closes mid-way.
@Riverpod(keepAlive: true)
class LogoutController extends _$LogoutController {
  @override
  bool build() => false;

  /// Unsent ops that would be lost.
  Future<int> unsent() => ref.read(outboxRepositoryProvider).depth();

  /// Returns the ops still unsent after the drain budget.
  Future<int> sendNow() async {
    state = true;
    try {
      return await ref.read(outboxDrainerProvider).drainNow();
    } finally {
      if (ref.mounted) state = false;
    }
  }

  Future<void> logout() async {
    state = true;
    try {
      await ref.read(sessionControllerProvider.notifier).signOut();
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
