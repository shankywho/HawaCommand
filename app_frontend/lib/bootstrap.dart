import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/app.dart';
import 'package:hawa_app/app/background_entry.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/providers.dart';
import 'package:hawa_app/core/errors/app_logger.dart';
import 'package:hawa_app/core/errors/crash_reporter.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/notifications/fcm_background_handler.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/firebase/firebase_options_dev.dart';
import 'package:hawa_app/firebase/firebase_options_prod.dart';
import 'package:hawa_app/firebase/firebase_options_staging.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// Binding init; Firebase init and prefs load in parallel (no network before the first frame);
/// error handlers; ProviderScope; runApp (ARCHITECTURE §19).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.configure(level: Env.logLevel);
  final log = Logger('bootstrap');
  final missing = Env.missingKeys();
  if (missing.isNotEmpty) log.severe('missing env keys: ${missing.join(', ')}');

  final (prefs, firebaseReady) = await (SharedPreferences.getInstance(), _initFirebase()).wait;

  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Inter',
      'Noto Sans Devanagari',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });

  if (firebaseReady) FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  try {
    await Workmanager().initialize(callbackDispatcher);
  } on Object catch (e) {
    log.warning('workmanager unavailable', e);
  }

  final crash = CrashReporter(enabled: Env.crashReporting && firebaseReady)..install();
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const Material(
      child: Center(
        child: Padding(padding: EdgeInsets.all(24), child: Icon(Icons.error_outline, size: 48)),
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        crashReporterProvider.overrideWithValue(crash),
        ...appOverrides(),
      ],
      // Retry only transient failures, at most 3 times (ARCHITECTURE §4).
      retry: (count, error) => count < 3 && error is Failure && error.isTransient
          ? Duration(milliseconds: 400 * (1 << count))
          : null,
      child: const HawaApp(),
    ),
  );
}

Future<bool> _initFirebase() async {
  final options = switch (Env.flavor) {
    'prod' => prodFirebaseOptions(),
    'staging' => stagingFirebaseOptions(),
    _ => devFirebaseOptions(),
  };
  if (options == null) return false;
  try {
    await Firebase.initializeApp(options: options);
    return true;
  } on Object catch (e) {
    Logger('bootstrap').warning('firebase init failed', e);
    return false;
  }
}
