import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/features/driver_route/application/shift_controller.dart';
import 'package:hawa_app/features/driver_route/application/today_route_controller.dart';

/// D6 Shift summary (`/driver/shift/summary`): counts, HawaTag litres, verified so far, unsent
/// updates; End shift stops the location service and queues `shift_end`.
class ShiftSummaryScreen extends ConsumerStatefulWidget {
  const ShiftSummaryScreen({super.key});

  @override
  ConsumerState<ShiftSummaryScreen> createState() => _ShiftSummaryScreenState();
}

class _ShiftSummaryScreenState extends ConsumerState<ShiftSummaryScreen> {
  bool _ended = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final route = ref.watch(todayRouteControllerProvider).value;
    final shift = ref.watch(shiftControllerProvider);
    final unsent = ref.watch(outboxDepthProvider).value ?? 0;

    Widget row(IconData icon, String label) => ListTile(
      leading: Icon(icon, color: c.brandText),
      title: Text(label, style: text.titleMedium),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.driverSummaryTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (route != null) ...[
              row(
                Icons.checklist,
                l.driverSummaryCounts(
                  '${route.doneCount}',
                  '${route.skippedCount}',
                  '${route.pendingCount}',
                ),
              ),
              row(Icons.water_drop_outlined, l.driverSummaryLitres(Numbers.whole(route.tagLitres))),
              row(Icons.verified_outlined, l.driverSummaryVerified('${route.verifiedCount}')),
            ],
            if (unsent > 0) row(Icons.cloud_upload_outlined, l.driverSummaryUnsent('$unsent')),
            const SizedBox(height: 24),
            if (_ended || !shift.active) ...[
              Icon(Icons.location_off, size: 48, color: c.mutedForeground),
              const SizedBox(height: 8),
              Text(l.driverSummaryEnded, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: () => context.go(Routes.driver), child: Text(l.commonDone)),
            ] else
              BigActionButton(
                icon: Icons.stop_circle_outlined,
                label: l.driverSummaryEndConfirm,
                variant: BigActionVariant.danger,
                busy: shift.busy,
                onPressed: shift.busy
                    ? null
                    : () async {
                        await ref.read(shiftControllerProvider.notifier).end(route);
                        if (mounted) setState(() => _ended = true);
                      },
              ),
          ],
        ),
      ),
    );
  }
}
