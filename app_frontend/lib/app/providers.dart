import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/router/deep_links.dart';
import 'package:hawa_app/app/router/router.dart';
import 'package:hawa_app/core/network/dio_provider.dart';
import 'package:hawa_app/core/notifications/fcm_background_handler.dart';
import 'package:hawa_app/core/notifications/fcm_service.dart';
import 'package:hawa_app/core/notifications/in_app_messages.dart';
import 'package:hawa_app/core/notifications/local_notifications.dart';
import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:hawa_app/core/notifications/push_router.dart';
import 'package:hawa_app/core/realtime/event_deduper.dart';
import 'package:hawa_app/core/realtime/realtime_dispatcher.dart';
import 'package:hawa_app/core/realtime/ws_client.dart';
import 'package:hawa_app/core/realtime/ws_message.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/features/alerts/data/alerts_repository_impl.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/data/auth_repository_impl.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';
import 'package:hawa_app/features/driver_route/data/task_event_applier.dart';
import 'package:hawa_app/features/inspector/data/inspector_repository_impl.dart';
import 'package:logging/logging.dart';

/// Root overrides (ARCHITECTURE §4): wiring core seams to feature implementations.
///
/// Fake vs real remote sources are chosen inside each feature's `*RemoteSource` provider from
/// `Env.isFake('<feature>')` (USE_FAKE_API / FAKE_FEATURES), so features stay independent; tests
/// override those providers directly.
List<Override> appOverrides() => [
  tokenRefresherProvider.overrideWith((ref) => ref.watch(authRepositoryProvider).refreshTokens),
  sessionExpiredProvider.overrideWith(
    (ref) =>
        () => ref.read(sessionControllerProvider.notifier).onExpired(),
  ),
];

/// Eagerly wires realtime appliers, sync triggers and push routing once the app runs.
final appWiringProvider = Provider<AppWiring>((ref) {
  final wiring = AppWiring(ref)..start();
  ref.onDispose(wiring.dispose);
  return wiring;
});

class AppWiring {
  AppWiring(this.ref);

  final Ref ref;
  final _subs = <StreamSubscription<Object?>>[];
  static final _log = Logger('wiring');
  AppLifecycleListener? _lifecycle;
  Timer? _backgroundDisconnect;
  bool _resumed = true;
  PushRouter? _pushRouter;

  /// Routes a payload like a notification tap (in-app banner taps use it too).
  Future<void> open(PushPayload payload) async => _pushRouter?.open(payload);

  void start() {
    ref
      ..read(syncTriggersProvider)
      ..read(realtimeDispatcherProvider)
      // Feature appliers register their realtime handlers when first read.
      ..read(taskEventApplierProvider)
      ..read(inspectorEventApplierProvider)
      ..read(alertEventApplierProvider);

    final router = PushRouter(
      resolve: resolveDeepLink,
      activeRole: () => ref.read(activeRoleWireProvider),
      roles: () {
        final s = ref.read(sessionControllerProvider);
        return s is SessionSignedIn ? s.user.roles : const <String>[];
      },
      switchRole: (role) =>
          ref.read(sessionControllerProvider.notifier).chooseRole(UserRole.fromWire(role)),
      go: (route) => ref.read(routerProvider).go(route),
    );
    _pushRouter = router;
    final local = ref.read(localNotificationsProvider);
    final fcm = ref.read(fcmServiceProvider);

    unawaited(() async {
      final launch = await local.init();
      final initial = await fcm.start();
      final cold = initial ?? launch;
      if (cold != null) await _openWhenReady(router, cold);
    }());

    _subs
      ..add(local.taps.listen((p) => unawaited(router.open(p))))
      ..add(fcm.opened.listen((p) => unawaited(router.open(p))))
      ..add(fcm.messages.listen((p) => unawaited(_onForegroundPush(p))))
      // Fake mode has no FCM: alert events from the fake backend play the push's part.
      ..add(
        ref
            .read(realtimeClientProvider)
            .messages
            .where((m) => m.type == 'alert.requested')
            .listen(_onAlertEvent),
      );

    // WebSocket only in the foreground; disconnect 30 s after going to the background (§10.1).
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _resumed = true;
        _backgroundDisconnect?.cancel();
        if (ref.read(sessionControllerProvider) is SessionSignedIn) {
          ref.read(realtimeClientProvider).connect();
        }
      },
      onPause: () {
        _resumed = false;
        _backgroundDisconnect = Timer(const Duration(seconds: 30), () {
          if (!Env.anyFake) ref.read(realtimeClientProvider).disconnect();
        });
      },
    );
  }

  /// Cold start: wait for the session to restore before routing.
  Future<void> _openWhenReady(PushRouter router, PushPayload payload) async {
    for (var i = 0; i < 50 && ref.read(sessionControllerProvider) is SessionBooting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await router.open(payload);
  }

  Future<void> _onForegroundPush(PushPayload p) async {
    if (ref.read(eventDeduperProvider).isDuplicate(p.dedupeKey)) return;
    await storeAlert(ref.read(appDatabaseProvider), p);
    ref.read(syncTriggersProvider.notifier).fire(SyncTriggerKind.push, scope: p.type);
    ref.read(inAppMessagesProvider.notifier).show(p);
  }

  void _onAlertEvent(WsMessage m) {
    final p = PushPayload.fromData({...m.data, 'type': m.data['kind'] ?? 'unknown'});
    if (_resumed) {
      ref.read(inAppMessagesProvider.notifier).show(p);
      return;
    }
    final lang = ref.read(settingsStoreProvider).language ?? 'hi';
    unawaited(
      ref
          .read(localNotificationsProvider)
          .show(
            p,
            title: p.title ?? 'HawaCommand',
            body:
                '${p.body ?? ''}${p.isSimulated ? (lang == 'hi' ? ' · सिम्युलेटेड' : ' · Simulated') : ''}',
          ),
    );
    _log.fine('fake push shown: ${p.type}');
  }

  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _lifecycle?.dispose();
    _backgroundDisconnect?.cancel();
  }
}
