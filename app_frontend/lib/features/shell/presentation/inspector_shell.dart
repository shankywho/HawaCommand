import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/features/shell/presentation/role_shell_scaffold.dart';

/// Inspector shell: Targets · Map · More.
class InspectorShell extends StatelessWidget {
  const InspectorShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RoleShellScaffold(
      navigationShell: navigationShell,
      tabs: [
        ShellTab.branch(icon: Icons.fact_check_outlined, label: l.tabTargets, branch: 0),
        ShellTab.branch(icon: Icons.map_outlined, label: l.tabMap, branch: 1),
        RoleShellScaffold.more(l.tabMore),
      ],
    );
  }
}
