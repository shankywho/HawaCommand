import 'package:flutter/material.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/app/theme/tokens.dart';

enum BigActionVariant { primary, secondary, danger }

/// Icon + label button: 64 dp in driver/inspector shells ([field]), 48 dp elsewhere; outdoor
/// mode adds the 2 dp ink border (ARCHITECTURE §15). Labels wrap instead of truncating (Hindi).
class BigActionButton extends StatelessWidget {
  const BigActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = BigActionVariant.primary,
    this.field = true,
    this.busy = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final BigActionVariant variant;
  final bool field;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final height = field ? HawaTokens.fieldButtonHeight : HawaTokens.buttonHeight;
    final (bg, fg) = switch (variant) {
      BigActionVariant.primary => (c.brand, c.onBrand),
      BigActionVariant.secondary => (c.surfaceElevated, c.foreground),
      BigActionVariant.danger => (c.danger, c.onDanger),
    };
    final borderColor = variant == BigActionVariant.secondary || c.outdoor ? c.ink : bg;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: double.infinity),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          minimumSize: Size(64, height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HawaTokens.radiusMd),
            side: BorderSide(
              color: borderColor,
              width: c.outdoor || variant == BigActionVariant.secondary ? 2 : 0,
            ),
          ),
          textStyle: TextStyle(fontSize: field ? 18 : 16, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
              )
            else
              Icon(icon, size: field ? 26 : 22),
            const SizedBox(width: 10),
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ],
        ),
      ),
    );
  }
}
