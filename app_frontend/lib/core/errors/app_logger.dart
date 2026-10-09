import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// `package:logging` setup with redaction (ARCHITECTURE §17): phone numbers, OTP codes, bearer
/// tokens and presigned URLs never reach the console or crash breadcrumbs.
abstract final class AppLogger {
  static final _phone = RegExp(r'(\+?91[\s-]?)?[6-9]\d{4}[\s-]?\d{5}');
  static final _bearer = RegExp(r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*', caseSensitive: false);
  static final _jwt = RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*');
  static final _otp = RegExp(r'("?code"?\s*[:=]\s*"?)\d{4,8}');
  static final _token = RegExp(
    r'("?(?:access_token|refresh_token|token)"?\s*[:=]\s*"?)[^",\s&]+',
    caseSensitive: false,
  );
  static final _presigned = RegExp(r'(X-Amz-[A-Za-z]+=)[^&\s"]+');
  static final _queryToken = RegExp(r'([?&]token=)[^&\s"]+');

  static String redact(String input) => input
      .replaceAllMapped(_bearer, (m) => '${m[1]}[redacted]')
      .replaceAll(_jwt, '[jwt]')
      .replaceAllMapped(_token, (m) => '${m[1]}[redacted]')
      .replaceAllMapped(_otp, (m) => '${m[1]}[otp]')
      .replaceAllMapped(_presigned, (m) => '${m[1]}[redacted]')
      .replaceAllMapped(_queryToken, (m) => '${m[1]}[redacted]')
      .replaceAll(_phone, '[phone]');

  /// Sends records at [level] and above to the console (dev) or to [sink] (crash breadcrumbs).
  static void configure({required String level, void Function(String line)? sink}) {
    Logger.root.level = Level.LEVELS.firstWhere(
      (l) => l.name.toLowerCase() == level.toLowerCase(),
      orElse: () => Level.INFO,
    );
    Logger.root.onRecord.listen((record) {
      final line = redact(
        '${record.level.name} ${record.loggerName}: ${record.message}'
        '${record.error != null ? ' | ${record.error}' : ''}',
      );
      if (sink != null) {
        sink(line);
      } else {
        developer.log(line, name: 'hawa', level: record.level.value);
      }
    });
  }
}
