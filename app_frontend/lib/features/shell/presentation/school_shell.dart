import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/features/shell/presentation/role_shell_scaffold.dart';

/// School shell: Today · Air · Alerts · More (Alerts opens the shared inbox).
class SchoolShell extends StatelessWidget {
  const SchoolShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RoleShellScaffold(
      navigationShell: navigationShell,
      tabs: [
        ShellTab.branch(icon: Icons.wb_sunny_outlined, label: l.tabToday, branch: 0),
        ShellTab.branch(icon: Icons.air, label: l.tabAir, branch: 1),
        ShellTab.action(
          icon: Icons.notifications_outlined,
          label: l.tabAlerts,
          action: (context, _) => unawaited(context.push(Routes.alerts)),
        ),
        RoleShellScaffold.more(l.tabMore),
      ],
    );
  }
}
