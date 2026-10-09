import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/storage/wipe_service.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/widgets/confirm_sheet.dart';

final FutureProvider<bool> _backendHealthy = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(commandCenterApiProvider).healthy(),
);

/// Dev tools (`/settings/dev`, dev flavor only): drive the fake backend for the demo, and show
/// which features talk to the real HawaCommand backend.
class DevToolsScreen extends ConsumerWidget {
  const DevToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final fake = ref.watch(fakeBackendProvider);
    final offline = ref.watch(forcedOfflineProvider);
    final healthy = ref.watch(_backendHealthy);

    void toast(String msg) => ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
    void done({required bool ok}) {
      toast(ok ? l.devSent : l.devNothingToDo);
      ref.read(syncTriggersProvider.notifier).fire(SyncTriggerKind.manual);
    }

    final live = Env.realFeatureSet.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(l.devTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              healthy.value ?? false ? Icons.cloud_done : Icons.cloud_off,
              color: healthy.value ?? false ? c.brandText : c.dangerText,
            ),
            title: const Text('HawaCommand backend ${Env.apiBaseUrl}'),
            subtitle: Text(
              '${healthy.isLoading
                  ? '…'
                  : (healthy.value ?? false)
                  ? 'reachable'
                  : 'not reachable'}'
              ' · live: ${live.isEmpty ? '—' : live.join(', ')}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(_backendHealthy),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: Text(l.devFakeMode),
            subtitle: const Text(
              Env.useFakeApi ? 'USE_FAKE_API=true' : 'FAKE_FEATURES=${Env.fakeFeatures}',
            ),
          ),
          const Divider(),
          if (!Env.anyFake)
            ListTile(leading: const Icon(Icons.info_outline), title: Text(l.devOnlyFake))
          else ...[
            ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: Text(l.devSimulateSpray),
              onTap: () => done(ok: fake.simulateSpray()),
            ),
            ListTile(
              leading: const Icon(Icons.verified_outlined),
              title: Text(l.devSimulateVerify),
              onTap: () => done(ok: fake.simulateVerify()),
            ),
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: Text(l.devSimulateRouteChange),
              onTap: () => done(ok: fake.simulateRouteChange()),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.sensors_off),
              title: Text(l.devTagOffline),
              value: fake.tagOffline,
              onChanged: (v) {
                fake.setTagOffline(offline: v);
                done(ok: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l.devTestPush),
              onTap: () async {
                fake.simulateTestAlert(token: await ref.read(tokenStoreProvider).readAccess());
                done(ok: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: Text(l.devNewTarget),
              onTap: () {
                fake.simulateNewTarget();
                done(ok: true);
              },
            ),
            SwitchListTile(
              secondary: const Icon(Icons.wifi_off),
              title: Text(l.devGoOffline),
              value: offline,
              onChanged: (v) => ref.read(forcedOfflineProvider.notifier).set(offline: v),
            ),
          ],
          const Divider(),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: c.dangerText),
            title: Text(l.devResetDb),
            onTap: () async {
              final ok = await showConfirmSheet(
                context,
                title: l.devResetConfirm,
                confirmLabel: l.devResetDb,
                danger: true,
                icon: Icons.delete_forever_outlined,
              );
              if (!ok) return;
              await ref.read(wipeServiceProvider).wipeData();
              ref.read(syncTriggersProvider.notifier).fire(SyncTriggerKind.manual);
              toast(l.devResetDone);
            },
          ),
        ],
      ),
    );
  }
}
