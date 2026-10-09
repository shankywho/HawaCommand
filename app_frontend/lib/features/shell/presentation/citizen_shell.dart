import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/features/shell/presentation/role_shell_scaffold.dart';

/// Citizen shell: Map · Air · Report · My reports · More.
class CitizenShell extends StatelessWidget {
  const CitizenShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RoleShellScaffold(
      navigationShell: navigationShell,
      tabs: [
        ShellTab.branch(icon: Icons.map_outlined, label: l.tabMap, branch: 0),
        ShellTab.branch(icon: Icons.air, label: l.tabAir, branch: 1),
        ShellTab.branch(icon: Icons.photo_camera_outlined, label: l.tabReport, branch: 2),
        ShellTab.branch(icon: Icons.list_alt, label: l.tabMyReports, branch: 3),
        RoleShellScaffold.more(l.tabMore),
      ],
    );
  }
}
