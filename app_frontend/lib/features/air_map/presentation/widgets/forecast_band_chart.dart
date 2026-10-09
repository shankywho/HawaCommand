import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/pollution_overlay.dart';

/// PM2.5 forecast: the P10–P90 band shaded, P50 as a line coloured by AQI, hour ticks in IST.
/// Uncertainty is always drawn (DESIGN_SYSTEM: never a bare point forecast).
class ForecastBandChart extends StatelessWidget {
  const ForecastBandChart({
    required this.series,
    required this.issuedAt,
    this.hours = 24,
    this.height = 110,
    super.key,
  });

  final List<ForecastPoint> series;
  final DateTime issuedAt;
  final int hours;
  final double height;

  @override
  Widget build(BuildContext context) {
    final points = [
      for (final p in series)
        if (p.h <= hours) p,
    ];
    if (points.length < 2) return const SizedBox.shrink();
    final c = context.hawaColors;
    final lang = context.lang;
    final labels = <String>[
      for (final h in [0, hours ~/ 4, hours ~/ 2, 3 * hours ~/ 4, hours])
        IstTime.time(issuedAt.add(Duration(hours: h)), lang),
    ];
    return Semantics(
      label: context.l10n.airMapNext24h,
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _BandPainter(
                points,
                c.muted,
                c.foreground.withValues(alpha: 0.6),
                cvd: c.cvdPalette,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final l in labels)
                Text(l, style: TextStyle(fontSize: 10, color: c.mutedForeground)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BandPainter extends CustomPainter {
  _BandPainter(this.points, this.grid, this.axisText, {required this.cvd});

  final List<ForecastPoint> points;
  final bool cvd;
  final Color grid;
  final Color axisText;

  @override
  void paint(Canvas canvas, Size size) {
    final maxH = points.last.h.toDouble();
    final top = points.map((p) => p.p90).reduce(math.max) * 1.08;
    final bottom = math.max(0, points.map((p) => p.p10).reduce(math.min) * 0.85);
    double x(num h) => maxH == 0 ? 0 : h / maxH * size.width;
    double y(double v) => size.height - (v - bottom) / (top - bottom) * size.height;

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final yy = size.height * i / 2;
      canvas.drawLine(Offset(0, yy), Offset(size.width, yy), gridPaint);
    }

    final band = Path()..moveTo(x(points.first.h), y(points.first.p90));
    for (final p in points) {
      band.lineTo(x(p.h), y(p.p90));
    }
    for (final p in points.reversed) {
      band.lineTo(x(p.h), y(p.p10));
    }
    band.close();
    canvas.drawPath(
      band,
      Paint()..color = AqiGradient.forPm25(points.first.p50, cvd: cvd).withValues(alpha: 0.18),
    );

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      canvas.drawLine(
        Offset(x(a.h), y(a.p50)),
        Offset(x(b.h), y(b.p50)),
        Paint()
          ..color = AqiGradient.forPm25((a.p50 + b.p50) / 2, cvd: cvd)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    TextPainter(
        text: TextSpan(
          text: '${top.round()}',
          style: TextStyle(fontSize: 9, color: axisText),
        ),
        textDirection: TextDirection.ltr,
      )
      ..layout()
      ..paint(canvas, const Offset(2, 1));
  }

  @override
  bool shouldRepaint(_BandPainter old) => old.points != points || old.cvd != cvd;
}
