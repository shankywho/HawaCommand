import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/core/location/shift_location_tracker.dart';
import 'package:hawa_app/core/notifications/push_token_registrar.dart';
import 'package:hawa_app/core/realtime/ws_client.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/storage/wipe_service.dart';
import 'package:hawa_app/core/sync/background_sync.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/features/auth/data/auth_repository_impl.dart';
import 'package:hawa_app/features/auth/domain/app_user.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

/// Session lifecycle: restore (offline, no network on cold start), login, role choice, expiry and
/// logout. The router's refresh listenable is bridged from this provider.
@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  static final _log = Logger('session');

  @override
  SessionState build() {
    ref.listen(appPreferencesControllerProvider.select((p) => p.languageChosen), (_, chosen) {
      final s = state;
      state = switch (s) {
        SessionBooting() => s,
        SessionSignedOut(:final expired) => SessionSignedOut(
          languageChosen: chosen,
          expired: expired,
        ),
        SessionSignedIn() => s.copyWith(languageChosen: chosen),
      };
    });
    Timer.run(() => unawaited(_restore()));
    return const SessionBooting();
  }

  bool get _languageChosen => ref.read(appPreferencesControllerProvider).languageChosen;

  Future<void> _restore() async {
    AppUser? user;
    try {
      user = await ref.read(authRepositoryProvider).restore();
    } on Object catch (e) {
      _log.warning('session restore failed', e);
    }
    if (!ref.mounted) return;
    if (user == null) {
      state = SessionSignedOut(languageChosen: _languageChosen);
      return;
    }
    await _enter(user, fromLogin: false);
    // Refresh /v1/me in the background; the cached user already rendered.
    unawaited(_refreshMeQuietly());
  }

  Future<void> _refreshMeQuietly() async {
    try {
      final fresh = await ref.read(authRepositoryProvider).refreshMe();
      final s = state;
      if (ref.mounted && s is SessionSignedIn && s.user.id == fresh.id) {
        final role = s.activeRole;
        final stillHeld = role == null || fresh.roles.contains(role.wire);
        state = s.copyWith(user: fresh, clearRole: !stillHeld);
      }
    } on Object catch (e) {
      _log.fine('me refresh skipped', e);
    }
  }

  /// Called by the OTP controller after a successful verify.
  Future<void> completeLogin(AppUser user) => _enter(user, fromLogin: true);

  Future<void> _enter(AppUser user, {required bool fromLogin}) async {
    final settings = ref.read(settingsStoreProvider);
    final session = SessionSignedIn(languageChosen: _languageChosen, user: user);
    final appRoles = session.appRoles;
    UserRole? active;
    final saved = UserRole.fromWire(settings.activeRole);
    if (appRoles.contains(saved)) {
      active = saved;
    } else if (appRoles.length == 1) {
      active = appRoles.single;
    }
    if (active != null) await settings.setActiveRole(active.wire);
    ref.read(currentUserIdProvider.notifier).set(user.id);
    final drainer = ref.read(outboxDrainerProvider)..resume();
    unawaited(drainer.start());
    unawaited(ref.read(crashReporterProvider).setUser(user.id));
    state = session.copyWith(activeRole: active);
    ref.read(realtimeClientProvider).connect();
    unawaited(BackgroundSync.schedulePeriodic());
    if (fromLogin) {
      unawaited(
        ref.read(pushTokenRegistrarProvider).register(locale: settings.language ?? user.lang),
      );
      // Send the language chosen before login so pushes/SMS arrive in it (SCREENS A2).
      final lang = settings.language;
      if (lang != null && lang != user.lang) unawaited(enqueueLanguage(lang));
    }
  }

  /// The user picked a role (A5) or switched from More.
  Future<void> chooseRole(UserRole role) async {
    final s = state;
    if (s is! SessionSignedIn || !s.appRoles.contains(role)) return;
    await ref.read(settingsStoreProvider).setActiveRole(role.wire);
    state = s.copyWith(activeRole: role);
    if (s.appRoles.length > 1) {
      try {
        await ref.read(authRepositoryProvider).switchRole(role.wire);
      } on Object catch (e) {
        _log.fine('switch-role not applied server-side', e);
      }
    }
    ref.read(syncTriggersProvider.notifier).fire(SyncTriggerKind.manual);
  }

  /// `PATCH /v1/me {lang}` through the outbox (proposed endpoint).
  Future<void> enqueueLanguage(String lang) async {
    if (state is! SessionSignedIn) return;
    await ref
        .read(outboxRepositoryProvider)
        .enqueue(
          kind: OpKind.profileUpdate,
          orderingKey: OrderingKeys.profile('lang'),
          coalesceKey: OrderingKeys.profile('lang'),
          payload: {
            'field': 'me',
            'body': {'lang': lang},
          },
        );
  }

  /// Refresh token rejected: data and outbox stay for the same user (OFFLINE_AND_SYNC §10).
  void onExpired() {
    if (state is! SessionSignedIn) return;
    ref.read(outboxDrainerProvider).pause();
    ref.read(realtimeClientProvider).disconnect();
    state = SessionSignedOut(languageChosen: _languageChosen, expired: true);
  }

  /// Logout wipe (OFFLINE_AND_SYNC §10): stop the shift tracker and WS, revoke best-effort,
  /// delete the FCM token, wipe local data except the language.
  Future<void> signOut() async {
    await ref.read(shiftLocationTrackerProvider).stop();
    ref.read(shiftActiveFlagProvider.notifier).set(active: false);
    ref.read(realtimeClientProvider).disconnect();
    await ref.read(authRepositoryProvider).logout();
    await ref.read(pushTokenRegistrarProvider).unregister();
    await BackgroundSync.cancelAll();
    await ref.read(wipeServiceProvider).wipeAll();
    ref.read(currentUserIdProvider.notifier).set(null);
    ref.read(appPreferencesControllerProvider.notifier).reload();
    state = SessionSignedOut(languageChosen: _languageChosen);
  }
}

/// The active role wire value (null while booting, signed out or picking).
@riverpod
String? activeRoleWire(Ref ref) => switch (ref.watch(sessionControllerProvider)) {
  SessionSignedIn(:final activeRole) => activeRole?.wire,
  _ => null,
};

/// The signed-in user, if any.
@riverpod
AppUser? currentUser(Ref ref) => switch (ref.watch(sessionControllerProvider)) {
  SessionSignedIn(:final user) => user,
  _ => null,
};
