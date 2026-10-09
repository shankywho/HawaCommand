import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/sync/sync_triggers.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/confirm_sheet.dart';
import 'package:hawa_app/core/widgets/conflict_banner.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/error_view.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_screen_chip.dart';
import 'package:hawa_app/core/widgets/stale_banner.dart';
import 'package:hawa_app/features/driver_route/application/route_change_detector.dart';
import 'package:hawa_app/features/driver_route/application/shift_controller.dart';
import 'package:hawa_app/features/driver_route/application/today_route_controller.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/next_stop_hero.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/route_feedback.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/shift_bar.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/stop_card.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// D1 Today's route (`/driver`): shift control, the next stop, and the ordered stop list. The drift
/// stream renders instantly from cache; refresh runs in the background.
class TodayRouteScreen extends ConsumerStatefulWidget {
  const TodayRouteScreen({super.key});

  @override
  ConsumerState<TodayRouteScreen> createState() => _TodayRouteScreenState();
}

class _TodayRouteScreenState extends ConsumerState<TodayRouteScreen> {
  /// Task ids added or moved by the last re-plan, highlighted after "See changes".
  Set<String> _highlight = const {};

  Future<void> _askEnd(TodayRoute route) async {
    final l = context.l10n;
    final ok = await showConfirmSheet(
      context,
      title: l.driverEndShiftTitle,
      body: l.driverEndShiftAuto,
      confirmLabel: l.driverEndShift,
      icon: Icons.stop_circle_outlined,
    );
    ref.read(shiftControllerProvider.notifier).dismissAutoEnd();
    if (ok && mounted) await context.push(Routes.shiftSummary);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final date = ref.watch(serviceDateProvider);
    final routeAsync = ref.watch(todayRouteControllerProvider);
    final freshness = ref.watch(routeFreshnessProvider).value;
    final shift = ref.watch(shiftControllerProvider);
    final route = routeAsync.value;

    ref
      ..listen(todayRouteControllerProvider.select((r) => r.value), (_, next) {
        ref.read(shiftControllerProvider.notifier).routeChanged(next);
      })
      ..listen(shiftControllerProvider.select((s) => s.autoEndPrompt), (_, prompt) {
        if (prompt && route != null) unawaited(_askEnd(route));
      })
      ..listen(shiftControllerProvider.select((s) => s.autoEnded), (_, ended) {
        if (ended) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.driverShiftAutoEnded)));
        }
      });

    final title = l.driverToday(
      '${IstTime.weekdayOfDate(date, context.lang)} ${IstTime.dayMonth(date, context.lang)}',
    );

    Widget body;
    if (route == null && routeAsync.isLoading) {
      body = const LoadingSkeleton();
    } else if (route == null && routeAsync.hasError) {
      body = ErrorView(
        error: routeAsync.error!,
        onRetry: ref.read(todayRouteControllerProvider.notifier).refresh,
      );
    } else if (route == null || route.stops.isEmpty) {
      body = RefreshIndicator(
        onRefresh: ref.read(todayRouteControllerProvider.notifier).refresh,
        child: ListView(
          children: [
            if (freshness?.error != null)
              FreshnessBanner(
                lastSuccess: freshness?.lastSuccess,
                staleAfter: const Duration(minutes: 15),
                error: freshness?.error,
              ),
            const SizedBox(height: 80),
            EmptyState(icon: Icons.route_outlined, message: l.driverEmpty),
          ],
        ),
      );
    } else {
      final next = route.nextStop;
      body = RefreshIndicator(
        onRefresh: ref.read(todayRouteControllerProvider.notifier).refresh,
        child: CustomScrollView(
          slivers: [
            SliverList.list(
              children: [
                if (route.hasSimulated) const SimulatedScreenChip(),
                FreshnessBanner(
                  lastSuccess: freshness?.lastSuccess,
                  staleAfter: const Duration(minutes: 15),
                  error: freshness?.error,
                  onRetry: ref.read(todayRouteControllerProvider.notifier).refresh,
                ),
                const ConflictBanner(),
                RouteChangedBanner(
                  onSeeChanges: () {
                    final diff = ref.read(routeChangeNoticeProvider);
                    setState(() => _highlight = {...?diff?.added});
                    ref.read(routeChangeNoticeProvider.notifier).dismiss();
                  },
                ),
                ShiftBar(route: route),
                if (shift.needsResume)
                  MaterialBanner(
                    backgroundColor: c.warning.withValues(alpha: 0.15),
                    content: Text(l.shiftResumePrompt),
                    actions: [
                      TextButton(
                        onPressed: () => ref
                            .read(shiftControllerProvider.notifier)
                            .resume(
                              route,
                              notificationTitle: l.shiftNotificationTitle,
                              notificationBody: l.shiftNotificationBody,
                            ),
                        child: Text(l.shiftResume),
                      ),
                    ],
                  ),
                if (next != null)
                  NextStopHero(route: route, stop: next)
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.celebration_outlined, size: 56, color: c.brand),
                        const SizedBox(height: 8),
                        Text(
                          l.driverAllDone,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        if (shift.active) ...[
                          const SizedBox(height: 16),
                          BigActionButton(
                            icon: Icons.stop_circle_outlined,
                            label: l.driverEndShift,
                            onPressed: () => context.push(Routes.shiftSummary),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            SliverList.builder(
              itemCount: route.stops.length,
              itemBuilder: (_, i) {
                final s = route.stops[i];
                if (identical(s, next)) return const SizedBox.shrink();
                return StopCard(
                  stop: s,
                  position: route.positionOf(s.taskId),
                  highlighted: _highlight.contains(s.taskId),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: ShellAppBar(title: title),
      body: AutoDoneOverlay(child: body),
    );
  }
}
