import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/aqi_palette.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/air_sheets.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/forecast_band_chart.dart';

/// Drag handle at the top of the map's bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.hawaColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

/// No route yet: the city right now (GRAP, PM2.5 with range, 24 h band) and the worst hotspots.
class AirSummaryPanel extends StatelessWidget {
  const AirSummaryPanel({
    required this.data,
    required this.scrollController,
    required this.onHotspot,
    required this.onRefresh,
    required this.refreshing,
    super.key,
  });

  final AirMapData data;
  final ScrollController scrollController;
  final ValueChanged<Hotspot> onHotspot;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final fc = data.forecast;
    final now = fc?.series.isNotEmpty ?? false ? fc!.series.first : null;
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SheetHandle(),
        Row(
          children: [
            Expanded(child: Text(l.airMapCityNow, style: text.titleMedium)),
            if (data.isSimulated) const SimulatedBadge(),
            IconButton(
              tooltip: l.airMapRefresh,
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        if (now != null) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Pm25Chip(now.p50, large: true),
              if (fc!.grapStage > 0) _GrapChip(stage: fc.grapStage),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l.airMapCityPm(now.p50.round().toString())} · '
            '${l.airMapLikely(math.min(now.p10, now.p90).round().toString(), math.max(now.p10, now.p90).round().toString())}',
            style: text.bodyMedium,
          ),
          if (fc.grapHeadline != null) ...[
            const SizedBox(height: 4),
            Text(fc.grapHeadline!, style: text.bodySmall?.copyWith(color: c.mutedForeground)),
          ],
          const SizedBox(height: 12),
          Text(l.airMapNext24h, style: text.titleSmall),
          const SizedBox(height: 8),
          ForecastBandChart(series: fc.series, issuedAt: fc.issuedAt),
        ],
        if (data.hotspots.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(l.airMapWorstAreas, style: text.titleSmall),
          for (final h in data.hotspots.take(10))
            ListTile(
              contentPadding: EdgeInsets.zero,
              onTap: () => onHotspot(h),
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: AqiPalette.of(h.category, cvd: c.cvdPalette).fill,
                child: Text(
                  '${h.rank}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AqiPalette.of(h.category, cvd: c.cvdPalette).onFill,
                  ),
                ),
              ),
              title: Text(h.place, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                l.airMapHotspotRow(
                  h.ward ?? '—',
                  h.cause.label(l),
                  Numbers.percent(h.causeConfidence),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Pm25Chip(h.pm25),
            ),
        ],
        const SizedBox(height: 12),
        Text(
          l.airMapUpdated(IstTime.time(data.grid.asOf, context.lang)),
          style: text.bodySmall?.copyWith(color: c.mutedForeground),
        ),
        const SizedBox(height: 4),
        Text(l.airMapModelNote, style: text.bodySmall?.copyWith(color: c.mutedForeground)),
      ],
    );
  }
}

class _GrapChip extends StatelessWidget {
  const _GrapChip({required this.stage});

  final int stage;

  @override
  Widget build(BuildContext context) {
    final colors = AqiPalette.grap(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        grapLabel(stage, context.l10n),
        style: TextStyle(color: colors.onFill, fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
  }
}
