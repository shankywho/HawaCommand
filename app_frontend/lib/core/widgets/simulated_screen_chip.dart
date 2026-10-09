import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';

/// Top-of-screen chip: "Includes simulated data" with the flask icon (SCREENS §0.1).
class SimulatedScreenChip extends StatelessWidget {
  const SimulatedScreenChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.simulated.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.simulated),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science, size: 16, color: c.simulatedText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.l10n.commonIncludesSimulated,
                  style: TextStyle(
                    color: c.simulatedText,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
