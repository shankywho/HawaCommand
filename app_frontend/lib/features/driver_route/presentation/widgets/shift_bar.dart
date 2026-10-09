import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/features/driver_route/application/shift_controller.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/presentation/permission_education_screen.dart';

/// SHIFT OFF [START SHIFT] / Shift on: location shared [END SHIFT]. Start asks for location
/// (education first), then starts the foreground service; the `shift_start` op queues offline.
class ShiftBar extends ConsumerWidget {
  const ShiftBar({required this.route, super.key});

  final TodayRoute route;

  static Future<void> startShift(BuildContext context, WidgetRef ref, TodayRoute route) async {
    final l = context.l10n;
    if (!await ensurePermission(context, ref, AppPermission.location)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.driverLocationNeeded)));
      }
      return;
    }
    await ref
        .read(shiftControllerProvider.notifier)
        .start(
          route,
          notificationTitle: l.shiftNotificationTitle,
          notificationBody: l.shiftNotificationBody,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final shift = ref.watch(shiftControllerProvider);
    final offline = ref.watch(networkStatusProvider).value?.isOffline ?? false;
    final on = shift.active;
    return Material(
      color: on ? c.brand.withValues(alpha: 0.1) : c.muted,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Icon(
              on ? Icons.share_location : Icons.location_disabled,
              color: on ? c.brandText : c.mutedForeground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                on ? (offline ? l.driverShiftQueued : l.driverShiftOn) : l.driverShiftOff,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (shift.busy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (on)
              OutlinedButton(
                onPressed: () => context.push(Routes.shiftSummary),
                child: Text(l.driverEndShift),
              )
            else
              FilledButton(
                onPressed: () => startShift(context, ref, route),
                child: Text(l.driverStartShift),
              ),
          ],
        ),
      ),
    );
  }
}
