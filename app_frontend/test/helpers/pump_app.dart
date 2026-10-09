import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hawa_app/app/l10n/gen/app_localizations.dart';
import 'package:hawa_app/app/theme/app_theme.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_clock.dart';
import 'fixtures.dart';

/// Sync triggers without timers or lifecycle listeners (tests drive refreshes directly).
class QuietSyncTriggers extends SyncTriggers {
  @override
  SyncTrigger? build() => null;

  @override
  void fire(SyncTriggerKind kind, {String? scope}) =>
      state = SyncTrigger(kind, (state?.seq ?? 0) + 1, scope: scope);
}

class FixedServiceDate extends ServiceDate {
  FixedServiceDate(this.date);

  final String date;

  @override
  String build() => date;
}

/// The standard test overrides: in-memory DB, in-memory tokens, mock prefs, the fixture fake
/// backend (no latency), a fixed clock at the fixtures' date, quiet sync triggers.
Future<List<Override>> testOverrides({
  String lang = 'en',
  Map<String, Object> prefs = const {},
  DateTime? now,
  TokenStore? tokens,
}) async {
  SharedPreferences.setMockInitialValues({'language': lang, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final clock = FakeClock(now ?? fixtureNow);
  return [
    sharedPreferencesProvider.overrideWithValue(sp),
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase.memory();
      ref.onDispose(db.close);
      return db;
    }),
    tokenStoreProvider.overrideWithValue(tokens ?? InMemoryTokenStore()),
    appClockProvider.overrideWithValue(clock),
    fakeBackendProvider.overrideWith((ref) {
      final b = testBackend(now: clock.now);
      ref.onDispose(b.dispose);
      return b;
    }),
    syncTriggersProvider.overrideWith(QuietSyncTriggers.new),
    serviceDateProvider.overrideWith(() => FixedServiceDate('2026-11-13')),
  ];
}

extension PumpApp on WidgetTester {
  /// Pumps [child] in a ProviderScope + MaterialApp with the app theme and l10n.
  Future<void> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
    String lang = 'en',
    bool outdoor = false,
    double textScale = 1,
  }) async {
    final base = await testOverrides(lang: lang);
    await pumpWidget(
      ProviderScope(
        overrides: [...base, ...overrides],
        child: MaterialApp(
          theme: outdoor
              ? AppTheme.outdoor(hindi: lang == 'hi')
              : AppTheme.light(hindi: lang == 'hi'),
          locale: Locale(lang),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child,
          ),
        ),
      ),
    );
  }
}
