import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fcm_service.g.dart';

/// Firebase Cloud Messaging (ARCHITECTURE §10.2). Everything is a no-op when this build has no
/// Firebase project configured (`Firebase.apps` empty): fake mode and local dev need none.
class FcmService {
  static final _log = Logger('fcm');

  bool get available => Firebase.apps.isNotEmpty;

  final _messages = StreamController<PushPayload>.broadcast();
  final _opened = StreamController<PushPayload>.broadcast();
  final _tokens = StreamController<String>.broadcast();
  bool _started = false;

  /// Foreground data messages.
  Stream<PushPayload> get messages => _messages.stream;

  /// Notification taps that opened the app from the background.
  Stream<PushPayload> get opened => _opened.stream;

  Stream<String> get tokenRefreshes => _tokens.stream;

  /// Wires the listeners; returns the cold-start message, if the app was opened from a push.
  Future<PushPayload?> start() async {
    if (!available || _started) return null;
    _started = true;
    try {
      FirebaseMessaging.onMessage.listen((m) => _messages.add(PushPayload.fromData(_data(m))));
      FirebaseMessaging.onMessageOpenedApp.listen(
        (m) => _opened.add(PushPayload.fromData(_data(m))),
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(_tokens.add);
      unawaited(_subscribeTopic());
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      return initial == null ? null : PushPayload.fromData(_data(initial));
    } on Object catch (e) {
      _log.warning('fcm start failed', e);
      return null;
    }
  }

  /// Broadcast alerts (`POST /v1/alerts/broadcast` on the backend) go to this topic.
  Future<void> _subscribeTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic(Env.fcmTopic);
    } on Object catch (e) {
      _log.warning('fcm topic subscribe failed', e);
    }
  }

  Future<String?> token() async {
    if (!available) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } on Object catch (e) {
      _log.warning('fcm token failed', e);
      return null;
    }
  }

  Future<void> deleteToken() async {
    if (!available) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } on Object catch (e) {
      _log.warning('fcm delete token failed', e);
    }
  }

  static Map<String, Object?> _data(RemoteMessage m) => {
    ...m.data,
    if (m.notification?.title != null && !m.data.containsKey('title'))
      'title': m.notification!.title,
    if (m.notification?.body != null && !m.data.containsKey('body')) 'body': m.notification!.body,
  };
}

@Riverpod(keepAlive: true)
FcmService fcmService(Ref ref) => FcmService();
