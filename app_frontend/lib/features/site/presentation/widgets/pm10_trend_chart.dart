import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/features/site/domain/site_score.dart';

/// 30-day PM10 median line (SCREENS M1). Axis units on the chart, first/last dates on the x axis,
/// a direct label on the latest value, and the summary sentence as its screen-reader label.
class Pm10TrendChart extends StatelessWidget {
  const Pm10TrendChart({required this.points, required this.summary, this.height = 180, super.key});

  /// Points with a value, oldest first.
  final List<SitePm10Point> points;

  /// "PM10 went from 290 to 229 µg/m³ over 30 days." (read instead of the drawing).
  final String summary;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.hawaColors;
    final theme = Theme.of(context);
    final lang = context.lang;
    final labelStyle = (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
      color: c.mutedForeground,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: Pm10TrendPainter(
            points: points,
            line: c.brandText,
            grid: c.border,
            labelStyle: labelStyle,
            valueStyle: labelStyle.copyWith(color: c.foreground, fontWeight: FontWeight.w600),
            textScaler: MediaQuery.textScalerOf(context),
            firstLabel: points.isEmpty ? '' : IstTime.dayMonth(points.first.date, lang),
            lastLabel: points.isEmpty ? '' : IstTime.dayMonth(points.last.date, lang),
          ),
        ),
      ),
    );
  }
}

class Pm10TrendPainter extends CustomPainter {
  Pm10TrendPainter({
    required this.points,
    required this.line,
    required this.grid,
    required this.labelStyle,
    required this.valueStyle,
    required this.textScaler,
    required this.firstLabel,
    required this.lastLabel,
  });

  final List<SitePm10Point> points;
  final Color line;
  final Color grid;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextScaler textScaler;
  final String firstLabel;
  final String lastLabel;

  static const unit = 'µg/m³';

  /// Rounds the value range outwards to a step of 10/25/50/100 so axis labels are tidy.
  static (double, double) niceRange(double min, double max) {
    final span = math.max(max - min, 1);
    final step = span > 400
        ? 100.0
        : span > 150
        ? 50.0
        : span > 40
        ? 25.0
        : 10.0;
    final lo = math.max(0, ((min - span * 0.1) / step).floor() * step).toDouble();
    final hi = ((max + span * 0.1) / step).ceil() * step;
    return (lo, hi <= lo ? lo + step : hi);
  }

  TextPainter _text(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final values = [for (final p in points) p.pm10P50!];
    final (lo, hi) = niceRange(values.reduce(math.min), values.reduce(math.max));

    final unitLabel = _text(unit, labelStyle);
    final hiLabel = _text(hi.round().toString(), labelStyle);
    final loLabel = _text(lo.round().toString(), labelStyle);
    final first = _text(firstLabel, labelStyle);
    final last = _text(lastLabel, labelStyle);

    final left = math.max(hiLabel.width, loLabel.width) + 8;
    final top = unitLabel.height + 6;
    final bottom = size.height - first.height - 6;
    final right = size.width - 8;
    final plot = Rect.fromLTRB(left, top, math.max(left + 1, right), math.max(top + 1, bottom));

    // Axis unit, top-left.
    unitLabel.paint(canvas, Offset.zero);

    // Grid at the bounds and the midpoint, labelled with values.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = plot.top + plot.height * f;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }
    hiLabel.paint(canvas, Offset(left - 6 - hiLabel.width, plot.top - hiLabel.height / 2));
    loLabel.paint(canvas, Offset(left - 6 - loLabel.width, plot.bottom - loLabel.height / 2));

    // x by calendar day, so a missing day leaves a proportional gap.
    final days = [for (final p in points) _dayIndex(p.date)];
    final span = math.max(1, days.last - days.first);
    Offset at(int i) => Offset(
      plot.left + plot.width * (days[i] - days.first) / span,
      plot.bottom - plot.height * ((values[i] - lo) / (hi - lo)).clamp(0, 1),
    );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Direct label on the latest point.
    final end = at(points.length - 1);
    canvas.drawCircle(end, 4, Paint()..color = line);
    final value = _text(values.last.round().toString(), valueStyle);
    final labelX = (end.dx - value.width - 6).clamp(plot.left, plot.right - value.width);
    final labelY = (end.dy - value.height - 6).clamp(0, size.height - value.height);
    value.paint(canvas, Offset(labelX, labelY.toDouble()));

    // First and last dates under the x axis.
    first.paint(canvas, Offset(plot.left, plot.bottom + 4));
    last.paint(canvas, Offset(plot.right - last.width, plot.bottom + 4));
  }

  static int _dayIndex(String date) =>
      DateTime.parse('${date}T00:00:00Z').millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

  @override
  bool shouldRepaint(Pm10TrendPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.line != line ||
      oldDelegate.grid != grid ||
      oldDelegate.labelStyle != labelStyle ||
      oldDelegate.textScaler != textScaler ||
      oldDelegate.firstLabel != firstLabel ||
      oldDelegate.lastLabel != lastLabel;
}
