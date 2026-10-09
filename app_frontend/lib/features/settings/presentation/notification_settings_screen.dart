import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';

/// Notifications sub-screen (SCREENS X3): per-kind toggles for citizens and schools. Route
/// notifications for drivers and inspectors cannot be turned off in the app (SMS covers them).
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  late Map<String, bool> _prefs = Map.of(ref.read(settingsStoreProvider).notificationPrefs);

  Future<void> _set(String kind, {required bool on}) async {
    setState(() => _prefs = {..._prefs, kind: on});
    await ref.read(settingsStoreProvider).setNotificationPrefs(_prefs);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final role = ref.watch(activeRoleWireProvider);
    final kinds = switch (role) {
      'citizen' => {
        'pollutant_warning': l.notifKindPollutant,
        'grap_outlook': l.notifKindGrap,
        'report_outcome': l.notifKindReports,
      },
      'school' => {'safe_window': l.notifKindSafeWindow, 'pollutant_warning': l.notifKindPollutant},
      _ => <String, String>{},
    };
    final locked = role == 'driver' || role == 'inspector';
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsNotifications)),
      body: ListView(
        children: [
          if (locked)
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l.notifKindRoute),
              subtitle: Text(l.settingsNotifRouteLocked),
            )
          else if (kinds.isEmpty)
            ListTile(leading: const Icon(Icons.info_outline), title: Text(l.settingsNotifNone)),
          for (final e in kinds.entries)
            SwitchListTile(
              title: Text(e.value),
              value: _prefs[e.key] ?? true,
              onChanged: (v) => _set(e.key, on: v),
            ),
        ],
      ),
    );
  }
}
