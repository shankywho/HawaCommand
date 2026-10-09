import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `main()` with the instance loaded before `runApp`.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

abstract final class PrefKeys {
  static const session = 'hawa.session';
  static const accounts = 'hawa.demo_accounts';
  static const apiUrl = 'hawa.api_url';
  static const demoOnly = 'hawa.demo_only';
  static const lang = 'hawa.lang';
}
