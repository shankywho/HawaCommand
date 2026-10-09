import 'package:flutter/material.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A role row in the same shape as a route stop card.
class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.role,
    required this.onTap,
    this.selected = false,
    this.showChevron = true,
    super.key,
  });

  final AppRole role;
  final VoidCallback onTap;
  final bool selected;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Semantics(
      button: true,
      selected: selected,
      label: tr(role.labelHi, role.labelEn),
      child: HawaCard(
        onTap: onTap,
        borderColor: selected ? HawaColors.ink : HawaColors.line,
        borderWidth: selected ? 2 : 1,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected ? HawaColors.ink : HawaColors.line,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                role.icon,
                size: 26,
                color: selected ? HawaColors.paper : HawaColors.ink,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.primary(role.labelHi, role.labelEn),
                    style: tr.style(19, weight: FontWeight.w600, height: 1.3),
                  ),
                  if (tr.isBoth)
                    Text(
                      role.labelEn,
                      style: HawaText.sans(13, color: HawaColors.muted),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    tr.primary(role.descriptionHi, role.descriptionEn),
                    style: tr.style(12.5, color: HawaColors.muted2),
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: HawaColors.muted,
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet that returns the chosen [AppRole].
class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({super.key, this.current});

  final AppRole? current;

  static Future<AppRole?> show(BuildContext context, {AppRole? current}) =>
      showModalBottomSheet<AppRole>(
        context: context,
        isScrollControlled: true,
        builder: (_) => RolePickerSheet(current: current),
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.primary('आप कौन हैं?', 'Who are you?'),
              style: context.tr.style(24, weight: FontWeight.w700, height: 1.2),
            ),
            Text(
              context.tr(
                'डेमो खाता चुनें',
                'Pick a demo account',
                both: 'Pick a demo account',
              ),
              style: context.tr.style(14, color: HawaColors.muted),
            ),
            const SizedBox(height: 16),
            for (final role in AppRole.values) ...[
              RoleCard(
                role: role,
                selected: role == current,
                onTap: () => Navigator.pop(context, role),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
