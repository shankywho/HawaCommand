import 'package:flutter/material.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/aqi.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/aqi_chip.dart';
import 'package:hawa_app/core/widgets/confidence_chip.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/features/air_map/domain/air_data.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/forecast_band_chart.dart';

/// AQI chip from a PM2.5 value (number + category word + "indicative").
class Pm25Chip extends StatelessWidget {
  const Pm25Chip(this.pm25, {this.large = false, super.key});

  final double pm25;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final aqi = Aqi.fromPm25(pm25);
    return AqiChip(value: aqi, category: Aqi.category(aqi), large: large);
  }
}

String _bearing(BuildContext context, String bearing) {
  if (!context.isHindi) return bearing;
  return switch (bearing.toLowerCase()) {
    'north' => 'उत्तर',
    'south' => 'दक्षिण',
    'east' => 'पूर्व',
    'west' => 'पश्चिम',
    'north-west' || 'northwest' => 'उत्तर-पश्चिम',
    'north-east' || 'northeast' => 'उत्तर-पूर्व',
    'south-west' || 'southwest' => 'दक्षिण-पश्चिम',
    'south-east' || 'southeast' => 'दक्षिण-पूर्व',
    _ => bearing,
  };
}

/// Hotspot detail: value, likely cause with confidence, exposure, nearby schools and the 24 h
/// forecast band.
class HotspotSheet extends StatelessWidget {
  const HotspotSheet({
    required this.hotspot,
    required this.issuedAt,
    required this.onDirections,
    super.key,
  });

  final Hotspot hotspot;
  final DateTime issuedAt;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final h = hotspot;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.airMapHotspotTitle('${h.rank}'), style: text.titleMedium)),
                const SimulatedBadge(),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              [h.place, h.ward].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
              style: text.bodyMedium?.copyWith(color: c.mutedForeground),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Pm25Chip(h.pm25, large: true),
                ConfidenceChip(value: h.confidence),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.airSource(h.cause.label(l), Numbers.percent(h.causeConfidence)),
              style: text.bodyLarge,
            ),
            if (h.exposurePersonHours != null) ...[
              const SizedBox(height: 4),
              Text(
                l.airMapHotspotExposure(Numbers.whole(h.exposurePersonHours!)),
                style: text.bodyMedium,
              ),
            ],
            if (h.suspectBearing != null && h.suspectDistanceKm != null) ...[
              const SizedBox(height: 4),
              Text(
                l.airMapHotspotSuspect(
                  h.suspectDistanceKm!.toStringAsFixed(1),
                  _bearing(context, h.suspectBearing!),
                ),
                style: text.bodyMedium,
              ),
            ],
            if (h.forecast.length > 1) ...[
              const SizedBox(height: 16),
              Text(l.airMapNext24h, style: text.titleSmall),
              const SizedBox(height: 8),
              ForecastBandChart(series: h.forecast, issuedAt: issuedAt),
            ],
            if (h.schools.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l.airMapHotspotSchools, style: text.titleSmall),
              for (final s in h.schools)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.school_outlined),
                  title: Text(l.airMapHotspotSchool(s.name, s.distanceKm.toStringAsFixed(1))),
                  trailing: s.assemblyAt == null ? null : Text(s.assemblyAt!),
                ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions),
                label: Text(l.airMapDirectionsHere),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tap on the map: the twin cell under the finger.
class CellSheet extends StatelessWidget {
  const CellSheet({
    required this.cell,
    required this.factor,
    required this.hoursAhead,
    required this.asOf,
    required this.onDirections,
    super.key,
  });

  final GridCellInfo? cell;
  final double factor;
  final int hoursAhead;
  final DateTime asOf;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final cell = this.cell;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l.airMapCellTitle, style: text.titleMedium)),
                if (cell != null) const SimulatedBadge(),
              ],
            ),
            const SizedBox(height: 12),
            if (cell == null)
              Text(l.airMapCellOutside, style: text.bodyLarge)
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pm25Chip(cell.pm25 * factor, large: true),
                  ConfidenceChip(value: cell.confidence),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                l.airMapCellPm(
                  (cell.pm25 * factor).round().toString(),
                  cell.pm10 == null ? '—' : (cell.pm10! * factor).round().toString(),
                ),
                style: text.bodyLarge,
              ),
              if (cell.ward != null) ...[
                const SizedBox(height: 4),
                Text(l.airMapCellWard(cell.ward!), style: text.bodyMedium),
              ],
              const SizedBox(height: 4),
              Text(
                hoursAhead == 0
                    ? l.airMapUpdated(IstTime.time(asOf, context.lang))
                    : l.airMapForecastAt(
                        IstTime.time(asOf.add(Duration(hours: hoursAhead)), context.lang),
                      ),
                style: text.bodySmall?.copyWith(color: c.mutedForeground),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDirections,
                icon: const Icon(Icons.directions),
                label: Text(l.airMapDirectionsHere),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
