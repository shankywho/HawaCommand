import 'dart:async';

import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/notifications/fcm_service.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_token_registrar.g.dart';

/// Enqueues `push_token` (latest wins) after login and on token refresh; deletes the FCM token on
/// logout (ARCHITECTURE §10.2).
class PushTokenRegistrar {
  PushTokenRegistrar({required this.fcm, required this.outbox});

  final FcmService fcm;
  final OutboxRepository outbox;
  StreamSubscription<String>? _sub;

  Future<void> register({required String locale}) async {
    final token = await fcm.token();
    if (token != null) await _enqueue(token, locale);
    await _sub?.cancel();
    _sub = fcm.tokenRefreshes.listen((t) => unawaited(_enqueue(t, locale)));
  }

  Future<void> _enqueue(String token, String locale) async {
    String version;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version}+${info.buildNumber}';
    } on Object {
      version = 'unknown';
    }
    await outbox.enqueue(
      kind: OpKind.pushToken,
      orderingKey: OrderingKeys.push,
      coalesceKey: OrderingKeys.push,
      payload: {
        'token': token,
        'platform': 'android',
        'app_flavor': Env.flavor,
        'app_version': version,
        'locale': locale,
      },
    );
  }

  Future<void> unregister() async {
    await _sub?.cancel();
    _sub = null;
    await fcm.deleteToken();
  }
}

@Riverpod(keepAlive: true)
PushTokenRegistrar pushTokenRegistrar(Ref ref) => PushTokenRegistrar(
  fcm: ref.watch(fcmServiceProvider),
  outbox: ref.watch(outboxRepositoryProvider),
);
