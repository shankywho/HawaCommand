import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/core/notifications/local_notifications.dart';
import 'package:hawa_app/features/shell/application/permission_controller.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';
import 'package:hawa_app/features/shell/presentation/widgets/more_sheet.dart';

/// A bottom tab: either a shell branch or an action (More sheet, pushed screen).
class ShellTab {
  const ShellTab.branch({required this.icon, required this.label, required int this.branch})
    : action = null;

  const ShellTab.action({
    required this.icon,
    required this.label,
    required void Function(BuildContext, WidgetRef) this.action,
  }) : branch = null;

  final IconData icon;
  final String label;
  final int? branch;
  final void Function(BuildContext context, WidgetRef ref)? action;
}

/// Shared scaffold for the role shells (StatefulShellRoute.indexedStack keeps each tab's stack).
/// The notifications education screen appears once, right after the role is first used.
class RoleShellScaffold extends ConsumerStatefulWidget {
  const RoleShellScaffold({required this.navigationShell, required this.tabs, super.key});

  final StatefulNavigationShell navigationShell;
  final List<ShellTab> tabs;

  static ShellTab more(String label) => ShellTab.action(
    icon: Icons.more_horiz,
    label: label,
    action: (context, ref) => unawaited(showMoreSheet(context, ref)),
  );

  @override
  ConsumerState<RoleShellScaffold> createState() => _RoleShellScaffoldState();
}

class _RoleShellScaffoldState extends ConsumerState<RoleShellScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_notificationsOnce()));
  }

  Future<void> _notificationsOnce() async {
    final repo = ref.read(permissionRepositoryProvider);
    if (repo.educationShown(AppPermission.notifications)) return;
    if (!mounted) return;
    await ensurePermission(context, ref, AppPermission.notifications);
    if (!mounted) return;
    // Channels need the localized names.
    await ref.read(localNotificationsProvider).registerChannels(context.l10n);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.navigationShell.currentIndex;
    final selected = widget.tabs.indexWhere((t) => t.branch == current);
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (i) {
          final tab = widget.tabs[i];
          if (tab.branch != null) {
            widget.navigationShell.goBranch(tab.branch!, initialLocation: tab.branch == current);
          } else {
            tab.action?.call(context, ref);
          }
        },
        destinations: [
          for (final t in widget.tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}
