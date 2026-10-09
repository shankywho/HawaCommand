import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/features/auth/domain/user_role.dart';

extension UserRoleLabel on UserRole {
  String label(AppLocalizations l) => switch (this) {
    UserRole.driver => l.roleDriver,
    UserRole.inspector => l.roleInspector,
    UserRole.school => l.roleSchool,
    UserRole.citizen => l.roleCitizen,
    UserRole.siteManager => l.roleSiteManager,
    UserRole.officer => l.roleOfficer,
    UserRole.admin => l.roleAdmin,
    UserRole.analyst => l.roleAnalyst,
    UserRole.unknown => l.commonUnknown,
  };

  IconData get icon => switch (this) {
    UserRole.driver => Icons.local_shipping,
    UserRole.inspector => Icons.search,
    UserRole.school => Icons.school,
    UserRole.citizen => Icons.person,
    UserRole.siteManager => Icons.apartment,
    _ => Icons.badge,
  };
}

/// Large role option with icon and label (A5).
class RoleTile extends StatelessWidget {
  const RoleTile({required this.role, required this.onTap, this.selected = false, super.key});

  final UserRole role;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: selected ? c.brand : c.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(role.icon, size: 32, color: c.brandText),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    role.label(context.l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.chevron_right,
                  color: c.foreground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
