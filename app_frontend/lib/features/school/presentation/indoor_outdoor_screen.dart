import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/features/school/application/school_controllers.dart';
import 'package:hawa_app/features/school/domain/school_models.dart';
import 'package:hawa_app/features/school/presentation/school_today_screen.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// S2 Indoor vs outdoor (`/school/air`): latest readings, the ratio, and the last 6 h with outdoor
/// solid and classroom dashed (distinguished by pattern + legend, not colour alone).
class IndoorOutdoorScreen extends ConsumerWidget {
  const IndoorOutdoorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    ref.watch(schoolInfoProvider);
    final io = ref.watch(indoorOutdoorProvider).value;
    final latest = io?.latest;
    return Scaffold(
      appBar: ShellAppBar(title: l.schoolAirTitle),
      body: io == null || latest == null
          ? EmptyState(icon: Icons.sensors_off, message: l.schoolNoReadings)
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (io.isSimulated) const SimulatedScreenChip(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (latest.outdoor != null)
                        _Reading(
                          label: l.schoolOutdoor,
                          value: '${Numbers.whole(latest.outdoor!)} µg/m³',
                          word: Aqi.category(Aqi.fromPm25(latest.outdoor!)).label(l),
                        ),
                      if (latest.indoor != null)
                        _Reading(
                          label: l.schoolIndoor,
                          value: '${Numbers.whole(latest.indoor!)} µg/m³',
                          word: Aqi.category(Aqi.fromPm25(latest.indoor!)).label(l),
                        ),
                      if (latest.co2 != null)
                        _Reading(label: l.schoolCo2, value: '${Numbers.whole(latest.co2!)} ppm'),
                      if (latest.ratio != null) ...[
                        const SizedBox(height: 4),
                        Text(l.schoolRatio(Numbers.percent(latest.ratio!)), style: text.titleSmall),
                      ],
                      Text(
                        IstTime.time(latest.ts, context.lang),
                        style: text.bodySmall?.copyWith(color: c.mutedForeground),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 180,
                    child: CustomPaint(painter: _IoPainter(io.series, c.foreground, c.border)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Wrap(
                    spacing: 16,
                    children: [
                      Text('━━  ${l.schoolLegendOutdoor}', style: text.bodySmall),
                      Text('╍╍  ${l.schoolLegendIndoor}', style: text.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final (icon, title, why) = adviceCopy(io.advice, l);
                    return ListTile(
                      leading: Icon(icon, color: c.brandText),
                      title: Text(title, style: text.titleMedium),
                      subtitle: why == null ? null : Text(why),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value, this.word});

  final String label;
  final String value;
  final String? word;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: text.bodyLarge)),
          Text(value, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (word != null) ...[const SizedBox(width: 8), Text(word!, style: text.bodyMedium)],
        ],
      ),
    );
  }
}

class _IoPainter extends CustomPainter {
  _IoPainter(this.series, this.ink, this.grid);

  final List<IndoorPoint> series;
  final Color ink;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final values = [
      for (final p in series) ...[?p.outdoor, ?p.indoor],
    ];
    final top = values.fold<double>(0, math.max) * 1.1;
    if (top <= 0) return;
    double x(int i) => i / (series.length - 1) * size.width;
    double y(double v) => size.height - v / top * size.height;
    final g = Paint()..color = grid;
    for (var i = 0; i <= 3; i++) {
      canvas.drawLine(Offset(0, size.height * i / 3), Offset(size.width, size.height * i / 3), g);
    }
    final outdoor = Path();
    var started = false;
    for (var i = 0; i < series.length; i++) {
      final v = series[i].outdoor;
      if (v == null) continue;
      started ? outdoor.lineTo(x(i), y(v)) : outdoor.moveTo(x(i), y(v));
      started = true;
    }
    canvas.drawPath(
      outdoor,
      Paint()
        ..color = ink
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    // Classroom: dashed.
    final dash = Paint()
      ..color = ink
      ..strokeWidth = 2.5;
    for (var i = 0; i < series.length - 1; i++) {
      final a = series[i].indoor;
      final b = series[i + 1].indoor;
      if (a == null || b == null || i.isOdd) continue;
      canvas.drawLine(Offset(x(i), y(a)), Offset(x(i + 1), y(b)), dash);
    }
  }

  @override
  bool shouldRepaint(_IoPainter old) => old.series != series;
}
