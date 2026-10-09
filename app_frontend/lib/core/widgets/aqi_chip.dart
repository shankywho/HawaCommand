import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/aqi_palette.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';

/// Colour + number + category word + "indicative", with the light-surface border
/// (DESIGN_SYSTEM §4). Missing category → muted "—" + "No estimate".
class AqiChip extends StatelessWidget {
  const AqiChip({required this.value, required this.category, this.large = false, super.key});

  final int? value;
  final AqiCategory category;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final colors = AqiPalette.of(
      category,
      cvd: c.cvdPalette,
      dark: Theme.of(context).brightness == Brightness.dark,
    );
    final known = value != null && category != AqiCategory.unknown;
    final text = known ? l.airAqi('$value', category.label(l)) : '— · ${l.commonNoEstimate}';
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 10 : 4),
        decoration: BoxDecoration(
          color: colors.fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.border, width: c.outdoor ? 2 : 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: colors.onFill,
            fontWeight: FontWeight.w600,
            fontSize: large ? 20 : 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
