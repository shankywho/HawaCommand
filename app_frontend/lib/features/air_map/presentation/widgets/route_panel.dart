import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/features/air_map/application/route_planner.dart';
import 'package:hawa_app/features/air_map/domain/departure_planner.dart';
import 'package:hawa_app/features/air_map/domain/place.dart';
import 'package:hawa_app/features/air_map/domain/route_option.dart';
import 'package:hawa_app/features/air_map/domain/travel_mode.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/air_sheets.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/air_summary_panel.dart';
import 'package:hawa_app/features/air_map/presentation/widgets/pollution_overlay.dart';
import 'package:url_launcher/url_launcher.dart';

extension TravelModeLabel on TravelMode {
  String label(AppLocalizations l) => switch (this) {
    TravelMode.walk => l.airMapModeWalk,
    TravelMode.cycle => l.airMapModeCycle,
    TravelMode.twoWheeler => l.airMapModeTwoWheeler,
    TravelMode.car => l.airMapModeCar,
  };

  IconData get icon => switch (this) {
    TravelMode.walk => Icons.directions_walk,
    TravelMode.cycle => Icons.pedal_bike,
    TravelMode.twoWheeler => Icons.two_wheeler,
    TravelMode.car => Icons.directions_car,
  };
}

/// Opens Google Maps directions through a few points of the chosen route, so turn-by-turn follows
/// the cleaner path rather than Google's fastest one.
Future<bool> openInGoogleMaps({
  required Place origin,
  required Place destination,
  required RouteOption route,
  required TravelMode mode,
}) {
  String p(double lat, double lon) => '${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}';
  final g = route.geometry;
  final vias = <String>[
    if (g.length > 8)
      for (final f in const [0.25, 0.5, 0.75])
        () {
          final pt = g[(g.length * f).floor()];
          return p(pt.lat, pt.lon);
        }(),
  ];
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': p(origin.point.lat, origin.point.lon),
    'destination': p(destination.point.lat, destination.point.lon),
    if (vias.isNotEmpty) 'waypoints': vias.join('|'),
    'travelmode': mode.googleMode,
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _routeError(AppLocalizations l, Object e) {
  final f = e is Failure ? e : null;
  return switch (f) {
    NotFoundFailure() => l.airMapNoRoute,
    ValidationFailure() => l.airMapSamePlace,
    NetworkFailure() || TimeoutFailure() || SimulatedOfflineFailure() => l.airMapRoutingOffline,
    _ => l.airMapNoRoute,
  };
}

/// The planner's bottom panel: mode, ranked routes, when to leave, start navigation.
class RoutePanel extends ConsumerWidget {
  const RoutePanel({required this.scrollController, super.key});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final plan = ref.watch(routePlannerProvider);
    final planner = ref.read(routePlannerProvider.notifier);
    final routes = plan.routes;
    final selected = plan.selectedRoute;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SheetHandle(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final m in TravelMode.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(m.icon, size: 18),
                    label: Text(m.label(l)),
                    selected: plan.mode == m,
                    onSelected: (_) => planner.setMode(m),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        switch (routes) {
          AsyncLoading() => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(l.airMapPlanning, style: text.bodyLarge),
              ],
            ),
          ),
          AsyncError(:final error) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.wrong_location_outlined, size: 40, color: c.mutedForeground),
                const SizedBox(height: 8),
                Text(_routeError(l, error), style: text.bodyLarge, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: planner.retry, child: Text(l.commonRetry)),
              ],
            ),
          ),
          AsyncData(:final value) when value.isEmpty => const SizedBox.shrink(),
          AsyncData(:final value) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.airMapRoutesCount('${value.length}'),
                style: text.labelLarge?.copyWith(color: c.mutedForeground),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < value.length; i++)
                RouteCard(
                  route: value[i],
                  fastest: value.firstWhere(
                    (r) => r.tags.contains(RouteTag.fastest),
                    orElse: () => value.first,
                  ),
                  selected: i == plan.selected.clamp(0, value.length - 1),
                  onTap: () => planner.select(i),
                ),
              if (plan.departures.length > 1) ...[
                const SizedBox(height: 12),
                DepartureChart(
                  options: plan.departures,
                  selectedHours: plan.departureHours,
                  onSelect: planner.setDeparture,
                ),
              ],
              const SizedBox(height: 16),
              if (selected != null && plan.origin != null && plan.destination != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: Text(l.airMapStartNav),
                    onPressed: () async {
                      final ok = await openInGoogleMaps(
                        origin: plan.origin!,
                        destination: plan.destination!,
                        route: selected,
                        mode: plan.mode,
                      );
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l.airMapNavFailed)));
                      }
                    },
                  ),
                ),
            ],
          ),
        },
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: planner.clear,
          icon: const Icon(Icons.close),
          label: Text(l.airMapClearRoute),
        ),
        const SizedBox(height: 8),
        Text(l.airMapDoseHelp, style: text.bodySmall?.copyWith(color: c.mutedForeground)),
        const SizedBox(height: 4),
        Text(l.airMapPrivacy, style: text.bodySmall?.copyWith(color: c.mutedForeground)),
      ],
    );
  }
}

/// One candidate route: time, distance, average air, inhaled dose with range, red-zone minutes and
/// the saving versus the fastest route.
class RouteCard extends StatelessWidget {
  const RouteCard({
    required this.route,
    required this.fastest,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final RouteOption route;
  final RouteOption fastest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final e = route.exposure;
    final minutes = (route.durationS / 60).round();
    final extra = ((route.durationS - fastest.durationS) / 60).round();
    final saving = fastest.exposure.doseUg <= 0 ? 0.0 : 1 - e.doseUg / fastest.exposure.doseUg;
    final cleaner = fastest.exposure.avgPm25 <= 0 ? 0.0 : 1 - e.avgPm25 / fastest.exposure.avgPm25;
    final tagColor = c.brand;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? c.brand.withValues(alpha: 0.08) : c.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? c.brand : c.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (route.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final t in [RouteTag.recommended, RouteTag.cleanest, RouteTag.fastest])
                        if (route.tags.contains(t))
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: t == RouteTag.recommended ? tagColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: tagColor),
                            ),
                            child: Text(
                              switch (t) {
                                RouteTag.recommended => l.airMapTagRecommended,
                                RouteTag.cleanest => l.airMapTagCleanest,
                                RouteTag.fastest => l.airMapTagFastest,
                              },
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: t == RouteTag.recommended ? c.onBrand : c.brandText,
                              ),
                            ),
                          ),
                    ],
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.airMapRouteSummary(
                          '$minutes',
                          (route.distanceM / 1000).toStringAsFixed(1),
                        ),
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (extra > 0)
                      Text(
                        l.airMapRouteExtra('$extra'),
                        style: text.bodyMedium?.copyWith(color: c.mutedForeground),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Pm25Chip(e.avgPm25),
                    Text(l.airMapRouteAvg('${e.avgPm25.round()}'), style: text.bodyMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l.airMapRouteDose(
                    Numbers.whole(e.doseUg),
                    Numbers.whole(e.doseLowUg),
                    Numbers.whole(e.doseHighUg),
                  ),
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  e.redZoneMinutes >= 1
                      ? l.airMapRouteRedZone('${e.redZoneMinutes.round()}')
                      : l.airMapRouteNoRedZone,
                  style: text.bodyMedium?.copyWith(
                    color: e.redZoneMinutes >= 1 ? c.dangerText : c.brandText,
                  ),
                ),
                if (!route.tags.contains(RouteTag.fastest) && cleaner >= 0.01) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.airMapRouteCleaner(Numbers.percent(cleaner)),
                    style: text.bodyMedium?.copyWith(
                      color: c.brandText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (!route.tags.contains(RouteTag.fastest) && saving >= 0.01) ...[
                  const SizedBox(height: 2),
                  Text(
                    l.airMapRouteSaving(Numbers.percent(saving)),
                    style: text.bodyMedium?.copyWith(
                      color: c.brandText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (route.via != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: c.mutedForeground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          l.airMapRouteVia,
                          style: text.bodySmall?.copyWith(color: c.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                ],
                if (e.coverage < 0.6) ...[
                  const SizedBox(height: 2),
                  Text(l.airMapRouteRough, style: text.bodySmall?.copyWith(color: c.warningText)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "When to leave": inhaled dose for departures over the next hours (forecast-driven).
class DepartureChart extends ConsumerWidget {
  const DepartureChart({
    required this.options,
    required this.selectedHours,
    required this.onSelect,
    super.key,
  });

  final List<DepartureOption> options;
  final int selectedHours;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final now = ref.watch(appClockProvider).now();
    final maxDose = options.map((o) => o.doseUg).fold<double>(0, math.max);
    final minDose = options.map((o) => o.doseUg).fold<double>(double.infinity, math.min);
    double t(DepartureOption o) =>
        maxDose - minDose < 1e-6 ? 0.5 : (o.doseUg - minDose) / (maxDose - minDose);
    final best = DeparturePlanner.best(options);
    String at(int h) => IstTime.time(now.add(Duration(hours: h)), context.lang);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.airMapLeaveTitle, style: text.titleSmall),
        const SizedBox(height: 4),
        Text(
          best == null
              ? l.airMapLeaveNow
              : l.airMapLeaveBest(
                  at(best.hoursAhead),
                  Numbers.percent(1 - best.doseUg / options.first.doseUg),
                ),
          style: text.bodyMedium?.copyWith(color: best == null ? c.foreground : c.brandText),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final o in options)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: o.hoursAhead == selectedHours,
                    label: l.airMapLeaveAt(at(o.hoursAhead)),
                    child: InkWell(
                      onTap: () => onSelect(o.hoursAhead),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 18 + 46 * t(o),
                              decoration: BoxDecoration(
                                color: RelativeScale.at(0.15 + 0.85 * t(o)),
                                borderRadius: BorderRadius.circular(4),
                                border: o.hoursAhead == selectedHours
                                    ? Border.all(color: c.foreground, width: 2)
                                    : best?.hoursAhead == o.hoursAhead
                                    ? Border.all(color: c.brand, width: 2)
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              o.hoursAhead == 0 ? l.airMapNow : at(o.hoursAhead),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: o.hoursAhead == selectedHours
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: c.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
