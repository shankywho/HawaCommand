import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/features/shell/presentation/role_shell_scaffold.dart';

/// Site manager shell: Site · More (VISION).
class SiteShell extends StatelessWidget {
  const SiteShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return RoleShellScaffold(
      navigationShell: navigationShell,
      tabs: [
        ShellTab.branch(icon: Icons.apartment, label: l.tabSite, branch: 0),
        RoleShellScaffold.more(l.tabMore),
      ],
    );
  }
}
