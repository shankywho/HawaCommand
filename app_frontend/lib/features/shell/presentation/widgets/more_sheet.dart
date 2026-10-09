import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/core/location/shift_location_tracker.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/widgets/confirm_sheet.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/domain/session_state.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';
import 'package:hawa_app/features/settings/application/logout_controller.dart';
import 'package:hawa_app/features/shell/presentation/widgets/role_tile.dart';

/// "More": Profile, Settings, Pending uploads, Switch role (more than one role), Log out.
Future<void> showMoreSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => const _MoreSheet(),
);

class _MoreSheet extends ConsumerWidget {
  const _MoreSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final roles = session is SessionSignedIn ? session.appRoles : const <UserRole>[];
    final depth = ref.watch(outboxDepthProvider).value ?? 0;
    void go(String route) {
      Navigator.of(context).pop();
      unawaited(context.push(route));
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session is SessionSignedIn && session.activeRole != UserRole.citizen)
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(l.airMapMoreEntry),
              onTap: () => go(Routes.map),
            ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l.moreProfile),
            onTap: () => go(Routes.profile),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l.moreSettings),
            onTap: () => go(Routes.settings),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(l.morePending),
            trailing: depth > 0 ? Badge(label: Text('$depth')) : null,
            onTap: () => go(Routes.syncQueue),
          ),
          if (roles.length > 1)
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(l.moreSwitchRole),
              onTap: () async {
                Navigator.of(context).pop();
                await switchRoleFlow(context, ref);
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.moreLogout),
            onTap: () async {
              Navigator.of(context).pop();
              await logoutFlow(context, ref);
            },
          ),
        ],
      ),
    );
  }
}

/// Role switch: a running shift ends only after the user confirms (SCREENS A5).
Future<void> switchRoleFlow(BuildContext context, WidgetRef ref) async {
  final session = ref.read(sessionControllerProvider);
  if (session is! SessionSignedIn) return;
  final l = context.l10n;
  final tracker = ref.read(shiftLocationTrackerProvider);
  if (tracker.active) {
    final ok = await showConfirmSheet(
      context,
      title: l.moreSwitchRole,
      body: l.switchRoleShiftWarn,
      confirmLabel: l.moreSwitchRole,
    );
    if (!ok) return;
    await tracker.stop();
  }
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<UserRole>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in session.appRoles) ...[
              RoleTile(
                role: r,
                selected: r == session.activeRole,
                onTap: () => Navigator.of(ctx).pop(r),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
  if (picked == null || picked == session.activeRole) return;
  await ref.read(sessionControllerProvider.notifier).chooseRole(picked);
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l.roleSwitched(picked.label(l)))));
  context.go(Routes.homeFor(picked.wire));
}

/// Logout with the unsent-outbox warning (SCREENS X3).
Future<void> logoutFlow(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final controller = ref.read(logoutControllerProvider.notifier);
  var unsent = await controller.unsent();
  if (!context.mounted) return;
  if (unsent > 0) {
    final send = await showConfirmSheet(
      context,
      title: l.settingsLogout,
      body: l.settingsLogoutWarn('$unsent'),
      confirmLabel: l.settingsSendNow,
      icon: Icons.cloud_upload,
      cancelLabel: l.settingsLogoutAnyway,
    );
    if (send) {
      unsent = await controller.sendNow();
      if (unsent > 0) return; // still unsent: stay signed in, the queue keeps trying
    }
  } else {
    final ok = await showConfirmSheet(
      context,
      title: l.settingsLogout,
      confirmLabel: l.settingsLogout,
      icon: Icons.logout,
    );
    if (!ok) return;
  }
  await controller.logout();
}
