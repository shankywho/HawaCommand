import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// Purple "Simulated / सिम्युलेटेड" pill with the flask icon: never icon-only (CONTRACTS §1,
/// honesty rule). Shown on every item with `is_simulated: true`.
class SimulatedBadge extends StatelessWidget {
  const SimulatedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Semantics(
      label: context.l10n.commonSimulatedSemantics,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.simulated, borderRadius: BorderRadius.circular(999)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science, size: 14, color: c.onSimulated),
              const SizedBox(width: 4),
              Text(
                context.l10n.commonSimulated,
                style: TextStyle(color: c.onSimulated, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
