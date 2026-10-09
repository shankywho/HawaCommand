import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/providers.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/background_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

/// workmanager callback (OFFLINE_AND_SYNC §5.6): a minimal container in the background isolate
/// (own DB connection, Dio, generated client, executors), the same drainer code.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs), ...appOverrides()],
    );
    try {
      return await runBackgroundSync(container);
    } on Object {
      return false;
    } finally {
      container.dispose();
    }
  });
}
