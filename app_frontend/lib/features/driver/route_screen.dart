import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawacommand_app/app/theme.dart';
import 'package:hawacommand_app/core/air.dart';
import 'package:hawacommand_app/core/api_client.dart';
import 'package:hawacommand_app/core/i18n.dart';
import 'package:hawacommand_app/features/auth/session.dart';
import 'package:hawacommand_app/features/driver/driver_data.dart';
import 'package:hawacommand_app/features/driver/route_map.dart';
import 'package:hawacommand_app/widgets/common.dart';
import 'package:hawacommand_app/widgets/states.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Design screen 01 · Driver · today's route.
class RouteScreen extends ConsumerWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(sessionProvider)?.assetId ?? 'T-12';
    final routeAsync = ref.watch(driverRouteProvider(asset));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: hawaSystemUi,
      child: Scaffold(
        backgroundColor: HawaColors.paper,
        body: SafeArea(
          bottom: false,
          child: routeAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              message: HawaApi.describeError(error),
              onRetry: () => ref.invalidate(driverRouteProvider(asset)),
            ),
            data: (sourced) => _RouteBody(sourced: sourced, asset: asset),
          ),
        ),
      ),
    );
  }
}

class _RouteBody extends ConsumerWidget {
  const _RouteBody({required this.sourced, required this.asset});

  final Sourced<DriverRoute> sourced;
  final String asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = sourced.data;
    final hotspots = ref.watch(hotspotsProvider).value?.data ?? demoHotspots;
    final vehicle = ref.watch(vehiclePositionProvider(asset)).value;
    final running = ref.watch(routeRunProvider) != null;
    final current = route.currentIndex;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final tr = context.tr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AssetChip(route.asset),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr.isEn ? route.assetLabelEn : route.assetLabelHi,
                      style: tr.style(13, color: HawaColors.muted2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SourcePill(
                    live: sourced.isLive,
                    onTap: () => context.push('/settings'),
                  ),
                  IconButton(
                    tooltip: tr('होम', 'Home'),
                    onPressed: () => context.go('/'),
                    icon: const Icon(LucideIcons.circleUser, size: 20),
                    color: HawaColors.muted2,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                tr.primary('आज का रूट', "Today's route"),
                style: tr.style(
                  30,
                  weight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: tr.style(14, color: HawaColors.muted),
                  children: [
                    TextSpan(
                      text: tr.isBoth
                          ? "Today's route · ${route.shortDate} · "
                          : '${route.date == null ? route.shortDate : tr.shortDate(route.date!)} · ',
                    ),
                    TextSpan(
                      text: route.shortWindow,
                      style: HawaText.mono(14, color: HawaColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 150,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HawaColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: RouteMap(route: route, hotspots: hotspots, vehicle: vehicle),
        ),
        Expanded(
          child: Stack(
            children: [
              RefreshIndicator(
                color: HawaColors.teal,
                onRefresh: () async {
                  ref
                    ..invalidate(hotspotsProvider)
                    ..invalidate(vehiclePositionProvider(asset))
                    ..invalidate(driverRouteProvider(asset));
                  await ref.read(driverRouteProvider(asset).future);
                },
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 170 + bottomInset),
                  itemCount: route.stops.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => StopCard(
                    stop: route.stops[i],
                    active: i == current,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomPanel(
                  running: running,
                  bottomInset: bottomInset,
                  onStart: () {
                    if (!running) {
                      unawaited(HapticFeedback.mediumImpact());
                      ref.read(routeRunProvider.notifier).start();
                    }
                    unawaited(context.push('/driver/active'));
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.running,
    required this.bottomInset,
    required this.onStart,
  });

  final bool running;
  final double bottomInset;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset.clamp(12, 40)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FAF9F6), HawaColors.paper],
          stops: [0, 0.24],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(
              'छिड़काव HawaTag अपने-आप दर्ज करेगा',
              'HawaTag logs the spray automatically',
              both: 'छिड़काव HawaTag अपने-आप दर्ज करेगा · Spray is logged automatically',
            ),
            textAlign: TextAlign.center,
            style: context.tr.style(13, color: HawaColors.muted2),
          ),
          const SizedBox(height: 10),
          BigActionButton(
            icon: LucideIcons.play,
            labelHi: running ? 'रूट चालू है' : 'रूट शुरू करें',
            labelEn: running ? 'Open running route' : 'Start route',
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}

/// A numbered stop row (design: 56 px badge, Hindi title, English subtitle).
class StopCard extends StatelessWidget {
  const StopCard({
    required this.stop,
    this.active = false,
    this.emphasised = false,
    this.trailingLine,
    super.key,
  });

  final RouteStop stop;
  final bool active;

  /// 2 px ink border (the "next stop" card on screen 02).
  final bool emphasised;

  /// Replaces the subtitle + window lines (e.g. `07:00 · 2.4 km`).
  final String? trailingLine;

  @override
  Widget build(BuildContext context) {
    final done = stop.status == StopStatus.done && !active;
    final tr = context.tr;
    final subtitle = switch (tr.lang) {
      AppLang.both => stop.subtitle,
      AppLang.hi => stop.actionHi,
      AppLang.en => stop.actionEn,
    };
    return HawaCard(
      borderColor: emphasised ? HawaColors.ink : HawaColors.line,
      borderWidth: emphasised ? 2 : 1,
      child: Row(
        children: [
          StopBadge(number: stop.number, active: active, done: done),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.isEn ? stop.placeEn : stop.placeHi,
                  style: tr.style(19, weight: FontWeight.w600, height: 1.3),
                ),
                if (trailingLine == null) ...[
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: tr.isHi
                          ? HawaText.deva(13, color: HawaColors.muted)
                          : HawaText.sans(13, color: HawaColors.muted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    done ? '${stop.window} · ${tr('पूरा', 'done', both: 'done')}' : stop.window,
                    style: HawaText.mono(14, weight: FontWeight.w500),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    trailingLine!,
                    style: HawaText.mono(14, weight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
