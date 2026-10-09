import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';
import 'package:hawa_app/core/notifications/notification_channels.dart';
import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_notifications.g.dart';

/// flutter_local_notifications: channels, display and tap handling. The app renders data-only
/// pushes itself so it controls channel, language fallback and dedupe (ARCHITECTURE §10.2).
class LocalNotifications {
  LocalNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<PushPayload>.broadcast();
  bool _ready = false;
  static final _log = Logger('notifications');

  /// Taps on our notifications (routed by the push router).
  Stream<PushPayload> get taps => _taps.stream;

  Future<PushPayload?> init() async {
    if (_ready) return null;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_hawa'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          final p = _decode(r.payload);
          if (p != null) _taps.add(p);
        },
      );
      _ready = true;
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        return _decode(launch!.notificationResponse?.payload);
      }
    } on Object catch (e) {
      _log.warning('local notifications unavailable', e);
    }
    return null;
  }

  /// (Re)registers channels with names in the current language.
  Future<void> registerChannels(AppLocalizations l10n) async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    for (final c in NotificationChannels.all(l10n)) {
      await android.createNotificationChannel(c);
    }
  }

  /// Android 13+ runtime permission (asked only from the education screen).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<bool> enabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? true;
  }

  Future<void> show(PushPayload payload, {required String title, required String body}) async {
    if (!_ready) await init();
    final channel = NotificationChannels.forType(payload.type);
    final id =
        (payload.collapseKey ?? payload.alertId ?? payload.entityId ?? title).hashCode & 0x7fffffff;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel,
            channel,
            icon: 'ic_stat_hawa',
            importance:
                channel == NotificationChannels.routeUpdates ||
                    channel == NotificationChannels.airAlerts
                ? Importance.high
                : Importance.defaultImportance,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(body),
          ),
        ),
        payload: jsonEncode(payload.toData()),
      );
    } on Object catch (e) {
      _log.warning('show failed', e);
    }
  }

  static PushPayload? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw);
      return map is Map ? PushPayload.fromData(map.cast<String, Object?>()) : null;
    } on FormatException {
      return null;
    }
  }
}

@Riverpod(keepAlive: true)
LocalNotifications localNotifications(Ref ref) => LocalNotifications();
