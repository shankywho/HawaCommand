import 'package:flutter/material.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

enum StatusTone { neutral, brand, brandSolid, info, warning, danger }

/// Icon + word for task, report and inspection statuses (never colour alone).
class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.icon,
    required this.label,
    this.tone = StatusTone.neutral,
    super.key,
  });

  final IconData icon;
  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final (Color bg, Color fg, Color border) = switch (tone) {
      StatusTone.neutral => (c.muted, c.foreground, c.border),
      StatusTone.brand => (Colors.transparent, c.brandText, c.brand),
      StatusTone.brandSolid => (c.brand, c.onBrand, c.brand),
      StatusTone.info => (c.info, c.onInfo, c.info),
      StatusTone.warning => (Colors.transparent, c.warningText, c.warning),
      StatusTone.danger => (c.danger, c.onDanger, c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.outdoor ? c.ink : border, width: c.outdoor ? 2 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
