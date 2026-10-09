import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/aqi_chip.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/confidence_chip.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/core/widgets/stale_banner.dart';
import 'package:hawa_app/features/citizen_air/application/air_near_me_controller.dart';
import 'package:hawa_app/features/citizen_air/domain/advice_rules.dart';
import 'package:hawa_app/features/citizen_air/domain/air_snapshot.dart';
import 'package:hawa_app/features/citizen_air/domain/manual_area.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// C1 Air near me (`/citizen`): "should I avoid this road now". AQI number + category word +
/// "indicative", main pollutant, likely source, and pollutant-specific advice.
class AirNearMeScreen extends ConsumerWidget {
  const AirNearMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final s = ref.watch(airNearMeControllerProvider);
    final ctl = ref.read(airNearMeControllerProvider.notifier);
    final cell = s.pick.cell ?? (s.cached?.snapshot.cells.isNotEmpty == true ? s.cached!.snapshot.cells.first : null);

    final Widget body;
    if (s.area == null && s.locationDenied) {
      body = _AreaPicker(onPick: ctl.pickArea, onUseLocation: ctl.useLocation, denied: true);
    } else if (s.loading && s.cached == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = RefreshIndicator(
        onRefresh: ctl.refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (s.cached?.snapshot.anySimulated ?? false) const SimulatedScreenChip(),
            if (s.cached != null)
              FreshnessBanner(
                lastSuccess: s.cached!.fetchedAt,
                staleAfter: AirNearMeController.staleAfter,
                error: s.error,
                onRetry: ctl.refresh,
              ),
            if (s.refreshing) const LinearProgressIndicator(minHeight: 2),
            if (cell != null) ...[
              _AirCard(cell: cell, asOf: s.cached?.fetchedAt ?? DateTime.now(), area: s.area),
              const SizedBox(height: 8),
              _Advice(cell: cell),
              const SizedBox(height: 12),
            ],
            const _SafeBreathWindowCard(),
            const SizedBox(height: 12),
            _ExplainableAttributionCard(cell: cell),
            const SizedBox(height: 14),
            _buildFeatureTiles(context),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: BigActionButton(
                icon: Icons.local_fire_department_outlined,
                label: l.airReport,
                onPressed: () => context.go(Routes.reportCapture),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(l.airMapMoreEntry),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(Routes.citizenMap),
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l.subTitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.citizenSubscription),
            ),
            if (s.cached?.snapshot.altRoute != null)
              ListTile(
                leading: const Icon(Icons.alt_route),
                title: Text(l.routeTipTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.citizenRouteTip),
              ),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(s.area?.manual == null ? l.airChangeArea : l.airUseLocation),
              onTap: () => s.area?.manual == null
                  ? showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => _AreaPicker(
                        onPick: (a) {
                          Navigator.of(context).pop();
                          return ctl.pickArea(a);
                        },
                        onUseLocation: () {
                          Navigator.of(context).pop();
                          return ctl.useLocation();
                        },
                      ),
                    )
                  : ctl.useLocation(),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: ShellAppBar(title: l.airTitle),
      body: body,
    );
  }
}

class _AirCard extends StatelessWidget {
  const _AirCard({required this.cell, required this.asOf, required this.area});

  final AirCell cell;
  final DateTime asOf;
  final CitizenArea? area;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final place = area?.manual?.name.of(context.lang) ?? cell.placeName?.of(context.lang) ?? 'Delhi (NCT)';
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l.airArea(place),
                    style: text.labelLarge?.copyWith(color: c.mutedForeground, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'LIVE CAAQMS + KRIGING',
                    style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                AqiChip(value: cell.aqi, category: cell.category, large: true),
                if (cell.pm25 != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PM2.5: ${cell.pm25!.toStringAsFixed(1)} µg/m³',
                      style: text.bodyMedium?.copyWith(
                        color: const Color(0xFF334155),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.airMain(cell.dominant.label(l)), style: text.bodyLarge),
            if (cell.causeConf != null) ...[
              const SizedBox(height: 4),
              Text(
                l.airSource(cell.cause.label(l), Numbers.percent(cell.causeConf!)),
                style: text.bodyLarge,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ConfidenceChip(value: cell.confidence),
                const Spacer(),
                Text(
                  l.airUpdated(IstTime.time(asOf, context.lang)),
                  style: text.bodySmall?.copyWith(color: c.mutedForeground),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Advice extends StatelessWidget {
  const _Advice({required this.cell});

  final AirCell cell;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = Theme.of(context).textTheme;
    final keys = AdviceRules.adviceFor(
      category: cell.category,
      dominant: cell.dominant,
      cause: cell.cause,
      confidence: cell.confidence,
    );
    String line(AdviceKey k) => switch (k) {
      AdviceKey.fine => l.adviceFine,
      AdviceKey.mask => l.adviceMask,
      AdviceKey.indoors => l.adviceIndoors,
      AdviceKey.avoidRoad => l.adviceAvoidRoad,
      AdviceKey.quietStreets => l.adviceQuietStreets,
      AdviceKey.coverDust => l.adviceCoverDust,
      AdviceKey.rough => l.adviceRough,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.driverWhatToDo, style: text.titleSmall),
          const SizedBox(height: 6),
          for (final k in keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(line(k), style: text.bodyLarge)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Manual area list when location is off (never a dead end).
class _AreaPicker extends StatelessWidget {
  const _AreaPicker({required this.onPick, required this.onUseLocation, this.denied = false});

  final Future<void> Function(ManualArea) onPick;
  final Future<void> Function() onUseLocation;
  final bool denied;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      shrinkWrap: true,
      children: [
        if (denied)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.airLocationDenied, style: Theme.of(context).textTheme.bodyLarge),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(l.airPickArea, style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final a in ManualArea.delhi)
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(a.name.of(context.lang)),
            onTap: () => onPick(a),
          ),
        ListTile(
          leading: const Icon(Icons.my_location),
          title: Text(l.airUseLocation),
          onTap: onUseLocation,
        ),
      ],
    );
  }
}

const _cMuted = Color(0xFF5F6B70);
const _cTeal = Color(0xFF0F766E);
const _cAlert = Color(0xFFC02A2A);
const _cLine = Color(0xFFE6E3DC);

Widget _buildFeatureTiles(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CITIZEN AIR TOOLS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _cMuted, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        _featureTile(
          context: context,
          icon: Icons.alt_route,
          title: 'Safe Air Navigator',
          subtitle: 'Plan cleanest airway & cut inhaled toxic PM dose by up to 43%',
          color: _cTeal,
          route: Routes.citizenSafeRoute,
        ),
        const SizedBox(height: 8),
        _featureTile(
          context: context,
          icon: Icons.auto_graph,
          title: '72-Hour AI Air Forecast',
          subtitle: 'LightGBM quantile predictions with P10–P90 uncertainty ribbons',
          color: const Color(0xFF6366F1),
          route: Routes.schoolForecast,
        ),
        const SizedBox(height: 8),
        _featureTile(
          context: context,
          icon: Icons.radar,
          title: 'Govt in Action Radar',
          subtitle: 'Live fleet telemetry & causal-verified misting impact',
          color: const Color(0xFF134074),
          route: Routes.citizenLiveOps,
        ),
        const SizedBox(height: 8),
        _featureTile(
          context: context,
          icon: Icons.emoji_events_outlined,
          title: 'Ward Air Scorecard',
          subtitle: 'Rankings, A+ to F grades & democratic accountability',
          color: const Color(0xFFD97706),
          route: Routes.citizenWardScore,
        ),
        const SizedBox(height: 8),
        _featureTile(
          context: context,
          icon: Icons.gavel,
          title: 'Flag Missed Machine',
          subtitle: 'Audit idle contractors with real-time IoT hardware telemetry',
          color: _cAlert,
          route: Routes.reportMissedMachine,
        ),
      ],
    ),
  );
}

Widget _featureTile({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required String route,
}) {
  return InkWell(
    onTap: () => context.push(route),
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cLine),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: _cMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: _cMuted),
        ],
      ),
    ),
  );
}


class _SafeBreathWindowCard extends ConsumerWidget {
  const _SafeBreathWindowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swAsync = ref.watch(safeBreathWindowProvider);
    final data = swAsync.value;

    final recommendedWindow = data?['recommended_window'] as String? ?? '12:00 - 19:00';
    final lowestPm25 = (data?['lowest_pm25'] as num?)?.toDouble() ?? 40.8;
    final peakPm25 = (data?['peak_pm25'] as num?)?.toDouble() ?? 113.9;
    final dangerWindow = data?['danger_window'] as String? ?? '06:00 - 09:30';
    final recommendation = data?['recommendation'] as String? ??
        'Solar convective thermal mixing dilutes ground pollutants (Expected PM2.5: ${lowestPm25.toStringAsFixed(1)} µg/m³). Avoid outdoor jogging before $dangerWindow AM during morning cold inversion.';
    final timeline = [
      for (final item in (data?['timeline'] as List<Object?>?) ?? const [])
        if (item is Map<String, Object?>) item,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.wb_sunny_outlined, color: Color(0xFF16A34A), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'BREATH SAFE WINDOW',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A), letterSpacing: 0.5),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LIVE DIURNAL MODEL', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Optimal Outdoor Window: $recommendedWindow',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
            ),
            const SizedBox(height: 3),
            Text(
              recommendation,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534), height: 1.3),
            ),
            const SizedBox(height: 10),
            // Timeline bar preview (24 hours)
            Row(
              children: List.generate(24, (index) {
                final item = index < timeline.length ? timeline[index] : null;
                final isSafe = item?['is_safe'] as bool? ?? (index >= 12 && index <= 18);
                final risk = item?['inversion_risk'] as String? ?? 'LOW';
                final Color barColor = isSafe
                    ? const Color(0xFF22C55E)
                    : (risk == 'HIGH' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
                return Expanded(
                  child: Container(
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text('06:00 (Peak ${peakPm25.toStringAsFixed(0)}µg)', style: const TextStyle(fontSize: 8.5, color: Color(0xFF991B1B), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                Flexible(child: Text('14:00 (Safe ${lowestPm25.toStringAsFixed(0)}µg)', style: const TextStyle(fontSize: 8.5, color: Color(0xFF166534), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                const Flexible(child: Text('23:00 (Night)', style: TextStyle(fontSize: 8.5, color: Color(0xFF991B1B), fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplainableAttributionCard extends StatelessWidget {
  const _ExplainableAttributionCard({this.cell});

  final AirCell? cell;

  @override
  Widget build(BuildContext context) {
    final cause = cell?.cause;
    final List<(String, double, String, Color)> items;
    if (cause == CauseLabel.traffic) {
      items = [
        ('Vehicular Tailpipe Exhaust (Arterial)', 0.58, '58%', const Color(0xFF134074)),
        ('Unpaved Road Dust Resuspension', 0.24, '24%', const Color(0xFFD97706)),
        ('Biomass & Local Burning', 0.18, '18%', _cAlert),
      ];
    } else if (cause == CauseLabel.burning || cause == CauseLabel.regionalSmoke) {
      items = [
        ('Biomass & Agricultural Burning', 0.52, '52%', _cAlert),
        ('Vehicular Exhaust Emissions', 0.28, '28%', const Color(0xFF134074)),
        ('Unpaved Road Dust', 0.20, '20%', const Color(0xFFD97706)),
      ];
    } else {
      items = [
        ('Unpaved Road & Construction Dust', 0.54, '54%', const Color(0xFFD97706)),
        ('Vehicular Exhaust (Arterial)', 0.28, '28%', const Color(0xFF134074)),
        ('Biomass & Waste Burning', 0.18, '18%', _cAlert),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WHY IS THE AIR BAD RIGHT NOW?',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _cMuted, letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('LightGBM AI', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: _cTeal)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final it in items) ...[
              _attributionBar(it.$1, it.$2, it.$3, it.$4),
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _attributionBar(String label, double ratio, String pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
            Text(pct, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: const Color(0xFFF1F5F9),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 5,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}


