import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';

/// A/B/C grade tile (ARCHITECTURE §15 `SiteGrade`): A → brand + "A", B → warning + "B",
/// C → danger + "C" + stripe pattern. Never colour alone: the letter is always drawn and the
/// tile reads "Grade B" to screen readers. Unknown → neutral fill + "—".
class GradeBadge extends StatelessWidget {
  const GradeBadge({required this.grade, this.size = 72, super.key});

  final SiteGrade grade;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final l = context.l10n;
    final (Color fill, Color fg) = switch (grade) {
      SiteGrade.a => (c.brand, c.onBrand),
      SiteGrade.b => (c.warning, c.onWarning),
      SiteGrade.c => (c.danger, c.onDanger),
      SiteGrade.unknown => (c.muted, c.foreground),
    };
    final letter = grade.letter;
    return Semantics(
      label: letter == null ? l.siteGradeUnknown : l.siteGradeLabel(letter),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: c.outdoor || grade == SiteGrade.unknown ? c.ink : fill,
              width: c.borderWidth,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: CustomPaint(
              key: grade == SiteGrade.c ? const ValueKey('grade-stripes') : null,
              painter: grade == SiteGrade.c
                  ? StripePainter(color: fg.withValues(alpha: 0.28))
                  : null,
              child: Center(
                child: Text(
                  letter ?? '—',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: fg,
                    fontSize: size * 0.55,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagonal stripes: the non-colour cue for grade C (and for colour-blind viewers).
class StripePainter extends CustomPainter {
  const StripePainter({required this.color, this.gap = 10, this.width = 4});

  final Color color;
  final double gap;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(StripePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.gap != gap || oldDelegate.width != width;
}
