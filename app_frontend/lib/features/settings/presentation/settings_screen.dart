import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/shell/presentation/widgets/more_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';

final FutureProvider<PackageInfo> _packageInfo = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// X3 Settings (`/settings`): language, notifications, display, data saver, pending uploads,
/// switch role, licences, version, Dev tools (dev flavor) and Log out.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final prefs = ref.watch(appPreferencesControllerProvider);
    final ctl = ref.read(appPreferencesControllerProvider.notifier);
    final depth = ref.watch(outboxDepthProvider).value ?? 0;
    final session = ref.watch(sessionControllerProvider);
    final roles = session is SessionSignedIn ? session.appRoles : const <Object>[];
    final version = ref.watch(_packageInfo).value?.version ?? '—';

    Future<void> setLanguage(String lang) async {
      await ctl.setLanguage(lang);
      await ref.read(sessionControllerProvider.notifier).enqueueLanguage(lang);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l.settingsLanguage),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'hi', label: Text('हिन्दी')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {prefs.lang},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setLanguage(s.first),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l.settingsNotifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.notificationSettings),
          ),
          ListTile(leading: const Icon(Icons.contrast), title: Text(l.settingsDisplay)),
          RadioGroup<DisplayMode>(
            groupValue: prefs.displayMode,
            onChanged: (m) async {
              if (m != null) await ctl.setDisplayMode(m);
            },
            child: Column(
              children: [
                for (final m in DisplayMode.values)
                  RadioListTile<DisplayMode>(
                    contentPadding: const EdgeInsets.only(left: 56, right: 16),
                    value: m,
                    title: Text(switch (m) {
                      DisplayMode.auto => l.displayAuto,
                      DisplayMode.standard => l.displayStandard,
                      DisplayMode.dark => l.displayDark,
                      DisplayMode.outdoor => l.displayOutdoor,
                    }),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.palette_outlined),
            title: Text(l.settingsCvd),
            value: prefs.cvdPalette,
            onChanged: (v) => ctl.setCvdPalette(on: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.data_saver_on_outlined),
            title: Text(l.settingsDataSaver),
            subtitle: Text(l.settingsDataSaverHint),
            value: prefs.dataSaver,
            onChanged: (v) => ctl.setDataSaver(on: v),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(l.settingsPending('$depth')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.syncQueue),
          ),
          if (roles.length > 1)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l.settingsSwitchRole),
              onTap: () => switchRoleFlow(context, ref),
            ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.settingsLicences),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'HawaCommand',
              applicationVersion: version,
            ),
          ),
          if (Env.showDevTools && !Env.isProd)
            ListTile(
              leading: const Icon(Icons.build_outlined),
              title: Text(l.settingsDevTools),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.devTools),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.settingsVersion(version, Env.flavor)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: BigActionButton(
              icon: Icons.logout,
              label: l.settingsLogout,
              variant: BigActionVariant.secondary,
              onPressed: () => logoutFlow(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
