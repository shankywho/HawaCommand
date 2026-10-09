import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/numbers.dart';

/// "Confidence high (86 %)": word + percentage + a 5-segment meter, thresholds 0.7 / 0.4
/// (DESIGN_SYSTEM §2.5). Never colour alone.
class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({required this.value, this.showMeter = true, super.key});

  final double value;
  final bool showMeter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final level = ConfidenceLevel.of(value);
    final text = l.inspectorConfidence(level.label(l).toLowerCase(), Numbers.percent(value));
    final filled = (value.clamp(0.0, 1.0) * 5).ceil();
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMeter) ...[
            for (var i = 0; i < 5; i++)
              Container(
                width: 6,
                height: 14,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  color: i < filled ? c.foreground : Colors.transparent,
                  border: Border.all(color: c.foreground),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            const SizedBox(width: 6),
          ],
          Flexible(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
