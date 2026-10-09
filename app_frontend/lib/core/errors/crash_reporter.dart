import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:hawa_app/core/errors/app_logger.dart';
import 'package:logging/logging.dart';

/// Crashlytics wrapper (ARCHITECTURE §17). A no-op when crash reporting is off or Firebase is
/// not configured for this build, so dev and fake builds never need a Firebase project.
class CrashReporter {
  CrashReporter({required this.enabled});

  final bool enabled;
  static final _log = Logger('crash');

  FirebaseCrashlytics? get _c => enabled ? FirebaseCrashlytics.instance : null;

  void install() {
    final c = _c;
    if (c == null) return;
    FlutterError.onError = c.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(c.recordError(error, stack, fatal: true));
      return true;
    };
  }

  /// The user identifier is a SHA-256 of the user id, never a phone number.
  Future<void> setUser(String? userId) async {
    final c = _c;
    if (c == null) return;
    await c.setUserIdentifier(
      userId == null ? '' : sha256.convert(utf8.encode(userId)).toString(),
    );
  }

  Future<void> setKey(String key, Object value) async => _c?.setCustomKey(key, value);

  void breadcrumb(String line) => _c?.log(AppLogger.redact(line));

  /// Non-fatal: permanent outbox failures, refresh failures, WS protocol errors.
  Future<void> nonFatal(Object error, {String? code, StackTrace? stack}) async {
    _log.warning('non-fatal${code == null ? '' : ' [$code]'}', error);
    await _c?.recordError(error, stack, reason: code);
  }
}
