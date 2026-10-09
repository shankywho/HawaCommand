import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/features/driver_route/application/stop_actions_controller.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/driver_text.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/tag_status_chip.dart';

/// NEXT STOP 1 of 6: place, window, what to do, HawaTag status and NAVIGATE (always visible
/// without scrolling, SCREENS D1 acceptance 5).
class NextStopHero extends ConsumerWidget {
  const NextStopHero({required this.route, required this.stop, super.key});

  final TodayRoute route;
  final Stop stop;

  static Future<void> navigate(WidgetRef ref, Stop stop) async {
    await ref.read(stopActionsProvider.notifier).navigate(stop);
    unawaited(DriverText.navigate(stop.location));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.brand, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(Routes.stop(stop.taskId)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${l.driverNextStop.toUpperCase()}  ${l.driverStopOf('${route.positionOf(stop.taskId)}', '${route.activeStops.length}')}',
                    style: text.labelLarge?.copyWith(
                      color: c.brandText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (stop.isSimulated) const SimulatedBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stop.placeName.of(context.lang),
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(DriverText.window(stop, l, context.lang), style: text.bodyLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(DriverText.kindIcon(stop), color: c.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      DriverText.whatToDo(stop, l, asset: route.asset),
                      style: text.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TagStatusChip(asset: route.asset),
              if (stop.arrivedAt != null) ...[
                const SizedBox(height: 8),
                Text(l.driverYoureHere, style: text.titleSmall?.copyWith(color: c.brandText)),
              ],
              const SizedBox(height: 12),
              BigActionButton(
                icon: Icons.navigation,
                label: l.commonNavigate,
                onPressed: () => navigate(ref, stop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
