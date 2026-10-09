import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/status_pill.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/driver_text.dart';

/// One row of the route list: number, place, window, status (icon + word), pending-op clock.
class StopCard extends StatelessWidget {
  const StopCard({required this.stop, required this.position, this.highlighted = false, super.key});

  final Stop stop;
  final int position;

  /// Added or moved by the last re-plan ("See changes").
  final bool highlighted;

  static StatusTone toneOf(TaskStatus s) => switch (s) {
    TaskStatus.verified => StatusTone.brandSolid,
    TaskStatus.done || TaskStatus.verifying => StatusTone.brand,
    TaskStatus.inProgress || TaskStatus.enRoute => StatusTone.info,
    TaskStatus.skipped || TaskStatus.missed || TaskStatus.inconclusive => StatusTone.warning,
    TaskStatus.failed || TaskStatus.cancelled => StatusTone.danger,
    _ => StatusTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final status = stop.shownStatus;
    final cancelled = status == TaskStatus.cancelled;
    final done = DriverText.doneLine(stop, l);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: highlighted ? c.info.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: highlighted ? c.info : c.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push(Routes.stop(stop.taskId)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: status.isCompleted ? c.brand : c.muted,
                child: Text(
                  '$position',
                  style: TextStyle(
                    color: status.isCompleted ? c.onBrand : c.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.placeName.of(context.lang),
                      style: text.titleSmall?.copyWith(
                        decoration: cancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${IstTime.time(stop.windowStart, context.lang)} – ${IstTime.time(stop.windowEnd, context.lang)}',
                      style: text.bodyMedium?.copyWith(color: c.mutedForeground),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StatusPill(
                          icon: status.icon,
                          label: done ?? status.label(l),
                          tone: toneOf(status),
                        ),
                        if (stop.hasPendingOp)
                          Tooltip(
                            message: l.commonSavedWillSend,
                            child: Icon(Icons.schedule, size: 18, color: c.mutedForeground),
                          ),
                        if (stop.isSimulated) const SimulatedBadge(),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
