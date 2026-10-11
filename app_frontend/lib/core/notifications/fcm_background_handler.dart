import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';
import 'package:hawa_app/core/notifications/local_notifications.dart';
import 'package:hawa_app/core/notifications/push_payload.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/background_sync.dart';
import 'package:hawa_app/firebase/firebase_options_env.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Top-level background handler (ARCHITECTURE §10.2): no Riverpod container in this isolate.
/// It opens its own DB connection (WAL), inserts the alert row, shows a localized local
/// notification and schedules a one-off sync.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // This isolate has no Firebase app yet: initialize it with the same build-define options as
  // bootstrap() (every flavor uses firebaseOptionsFromEnv()).
  if (Firebase.apps.isEmpty) {
    final options = firebaseOptionsFromEnv();
    if (options == null) return;
    await Firebase.initializeApp(options: options);
  }
  final payload = PushPayload.fromData({...message.data});
  final db = AppDatabase.open();
  try {
    await storeAlert(db, payload);
    await db.syncStateDao.setDirty(payload.type == 'report_outcome' ? 'reports' : 'tasks');
  } finally {
    await db.close();
  }
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('language') ?? payload.lang ?? 'hi';
  final l10n = lookupAppLocalizations(Locale(lang));
  final title = payload.title ?? l10n.appTitle;
  final body = '${payload.body ?? ''}${payload.isSimulated ? l10n.pushSimulatedSuffix : ''}';
  await LocalNotifications().show(payload, title: title, body: body);
  await BackgroundSync.scheduleOneOff();
}

/// Upserts a push as an inbox row (shared with the foreground path).
Future<void> storeAlert(AppDatabase db, PushPayload p) async {
  final id = p.alertId;
  if (id == null) return;
  final now = DateTime.now().toUtc();
  await db.alertDao.upsertAll([
    AlertsTableCompanion.insert(
      id: id,
      kind: p.type,
      title: p.title ?? '',
      body: p.body ?? '',
      lang: p.lang ?? 'en',
      deepLink: Value(p.deepLink),
      receivedAt: p.sentAt ?? now,
      isSimulated: Value(p.isSimulated),
      payloadJson: jsonEncode(p.toData()),
    ),
  ]);
}
