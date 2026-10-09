import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/aqi_palette.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/features/school/application/school_controllers.dart';
import 'package:hawa_app/features/school/domain/school_models.dart';

/// S3 Forecast (`/school/forecast`): 72 h P50 line with the P10–P90 band (always drawn), school
/// hours shaded, the 250 µg/m³ alert line dashed, faint AQI bands, IST axis; "Show as table".
/// Live from the backend's AI-ML forecaster when `school_forecast` is real.
class ForecastScreen extends ConsumerStatefulWidget {
  const ForecastScreen({super.key});

  @override
  ConsumerState<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends ConsumerState<ForecastScreen> {
  bool _table = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final school = ref.watch(schoolInfoProvider).value;
    final fc = ref.watch(cellForecastProvider).value;
    final series = fc?.series ?? const <ForecastHour>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.schoolForecastTitle),
        actions: [
          TextButton(
            onPressed: () => setState(() => _table = !_table),
            child: Text(_table ? l.commonShowChart : l.commonShowTable),
          ),
        ],
      ),
      body: series.isEmpty
          ? EmptyState(icon: Icons.show_chart, message: l.schoolNoIssue)
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (fc!.isSimulated) const SimulatedScreenChip(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Builder(
                    builder: (_) {
                      final peak = series.reduce((a, b) => a.p50 >= b.p50 ? a : b);
                      return Text(
                        l.schoolForecastSummary(
                          Numbers.whole(peak.p50),
                          IstTime.time(peak.at, context.lang),
                        ),
                        style: text.bodyLarge,
                      );
                    },
                  ),
                ),
                if (_table)
                  DataTable(
                    columnSpacing: 16,
                    columns: [
                      DataColumn(label: Text(l.tableTime)),
                      const DataColumn(label: Text('P10'), numeric: true),
                      const DataColumn(label: Text('P50'), numeric: true),
                      const DataColumn(label: Text('P90'), numeric: true),
                    ],
                    rows: [
                      for (final h in series)
                        DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${IstTime.weekday(h.at, context.lang)} ${IstTime.time(h.at, context.lang)}',
                              ),
                            ),
                            DataCell(Text(h.p10 == null ? '—' : Numbers.whole(h.p10!))),
                            DataCell(Text(Numbers.whole(h.p50))),
                            DataCell(Text(h.p90 == null ? '—' : Numbers.whole(h.p90!))),
                          ],
                        ),
                    ],
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 240,
                      child: CustomPaint(
                        painter: _ForecastPainter(
                          series: series,
                          brand: c.brand,
                          ink: c.foreground,
                          grid: c.border,
                          dayStart: school?.dayStart ?? '07:30',
                          dayEnd: school?.dayEnd ?? '13:30',
                          cvd: c.cvdPalette,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(l.schoolForecastLegend, style: text.bodySmall),
                        Text('┄ ${l.schoolForecastThreshold}', style: text.bodySmall),
                        Text('▒ ${l.schoolForecastHours}', style: text.bodySmall),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      '${IstTime.time(series.first.at, context.lang)} → ${IstTime.weekday(series.last.at, context.lang)} '
                      '${IstTime.time(series.last.at, context.lang)} (IST) · µg/m³',
                      style: text.bodySmall?.copyWith(color: c.mutedForeground),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _ForecastPainter extends CustomPainter {
  _ForecastPainter({
    required this.series,
    required this.brand,
    required this.ink,
    required this.grid,
    required this.dayStart,
    required this.dayEnd,
    required this.cvd,
  });

  final List<ForecastHour> series;
  final Color brand;
  final Color ink;
  final Color grid;
  final String dayStart;
  final String dayEnd;
  final bool cvd;

  static const threshold = 250.0;

  @override
  void paint(Canvas canvas, Size size) {
    final t0 = series.first.at;
    final span = series.last.at.difference(t0).inMinutes.toDouble();
    final top = math.max(
      threshold * 1.1,
      series.map((h) => h.p90 ?? h.p50).reduce(math.max) * 1.08,
    );
    double x(DateTime t) => span == 0 ? 0 : t.difference(t0).inMinutes / span * size.width;
    double y(double v) => size.height - v / top * size.height;

    // Faint AQI bands (8 %).
    const bands = [
      (0.0, 30.0),
      (30.0, 60.0),
      (60.0, 90.0),
      (90.0, 120.0),
      (120.0, 250.0),
      (250.0, 1000.0),
    ];
    for (final (lo, hi) in bands) {
      if (lo > top) break;
      final cat = Aqi.category(Aqi.fromPm25((lo + math.min(hi, top)) / 2));
      canvas.drawRect(
        Rect.fromLTRB(0, y(math.min(hi, top)), size.width, y(lo)),
        Paint()..color = AqiPalette.of(cat, cvd: cvd).fill.withValues(alpha: 0.08),
      );
    }

    // School hours shaded per IST day.
    int mins(String hm) => int.parse(hm.split(':')[0]) * 60 + int.parse(hm.split(':')[1]);
    final startM = mins(dayStart);
    final endM = mins(dayEnd);
    final firstIst = IstTime.wall(t0);
    for (var d = 0; d <= 4; d++) {
      final dayIst = DateTime.utc(firstIst.year, firstIst.month, firstIst.day + d);
      final s = dayIst.add(Duration(minutes: startM)).subtract(IstTime.offset);
      final e = dayIst.add(Duration(minutes: endM)).subtract(IstTime.offset);
      final l = x(s).clamp(0.0, size.width);
      final r = x(e).clamp(0.0, size.width);
      if (r > l) {
        canvas.drawRect(
          Rect.fromLTRB(l, 0, r, size.height),
          Paint()..color = ink.withValues(alpha: 0.06),
        );
      }
    }

    // P10–P90 band (always drawn when present).
    final band = Path();
    final withRange = series.where((h) => h.p10 != null && h.p90 != null).toList();
    if (withRange.length > 1) {
      band.moveTo(x(withRange.first.at), y(withRange.first.p90!));
      for (final h in withRange) {
        band.lineTo(x(h.at), y(h.p90!));
      }
      for (final h in withRange.reversed) {
        band.lineTo(x(h.at), y(h.p10!));
      }
      band.close();
      canvas.drawPath(band, Paint()..color = brand.withValues(alpha: 0.18));
    }

    // Alert threshold (dashed).
    final ty = y(threshold);
    final dashPaint = Paint()
      ..color = ink.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    for (var dx = 0.0; dx < size.width; dx += 10) {
      canvas.drawLine(Offset(dx, ty), Offset(math.min(dx + 5, size.width), ty), dashPaint);
    }

    // P50 line.
    final line = Path()..moveTo(x(series.first.at), y(series.first.p50));
    for (final h in series.skip(1)) {
      line.lineTo(x(h.at), y(h.p50));
    }
    canvas
      ..drawPath(
        line,
        Paint()
          ..color = brand
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      )
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), Paint()..color = grid);
  }

  @override
  bool shouldRepaint(_ForecastPainter old) => old.series != series || old.cvd != cvd;
}
