import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/numbers.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/status_pill.dart';
import 'package:hawa_app/features/driver_route/application/stop_actions_controller.dart';
import 'package:hawa_app/features/driver_route/application/today_route_controller.dart';
import 'package:hawa_app/features/driver_route/domain/impact_summary.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/driver_text.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/next_stop_hero.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/stop_card.dart';
import 'package:hawa_app/features/driver_route/presentation/widgets/tag_status_chip.dart';

/// D3 Stop detail (`/driver/stops/:taskId`): what to do, when, status and the fallbacks.
/// "I've arrived" is local only; the server moves the stop to in_progress on HawaTag spray_start.
class StopDetailScreen extends ConsumerWidget {
  const StopDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final stop = ref.watch(stopDetailProvider(taskId)).value;
    final route = ref.watch(todayRouteControllerProvider).value;
    if (stop == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.place_outlined, message: l.driverNoRouteYet),
      );
    }
    final status = stop.shownStatus;
    final asset = route?.asset;
    final position = route?.positionOf(taskId) ?? stop.sequence;
    final total = route?.activeStops.length ?? position;
    final canManual = (asset?.tagCannotConfirm ?? false) && status.allowsManualDone;
    final done = DriverText.doneLine(stop, l);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.driverStopOf('$position', '$total')),
        actions: [
          if (stop.isSimulated)
            const Padding(padding: EdgeInsets.only(right: 12), child: SimulatedBadge()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            stop.placeName.of(context.lang),
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(DriverText.window(stop, l, context.lang), style: text.bodyLarge),
          const Divider(height: 32),
          Text(
            l.driverWhatToDo.toUpperCase(),
            style: text.labelLarge?.copyWith(color: c.mutedForeground),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(DriverText.kindIcon(stop), color: c.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(DriverText.whatToDo(stop, l, asset: asset), style: text.titleMedium),
              ),
            ],
          ),
          if (stop.instructions != null) ...[
            const SizedBox(height: 6),
            Text(stop.instructions!.of(context.lang), style: text.bodyLarge),
          ],
          if (stop.causeLabel != null && stop.causeConf != null) ...[
            const SizedBox(height: 6),
            Text(
              l.driverWhy(stop.causeLabel!.label(l), Numbers.percent(stop.causeConf!)),
              style: text.bodyLarge,
            ),
          ],
          const Divider(height: 32),
          Text(
            l.driverStatus.toUpperCase(),
            style: text.labelLarge?.copyWith(color: c.mutedForeground),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusPill(
                icon: status.icon,
                label: done ?? status.label(l),
                tone: StopCard.toneOf(status),
              ),
              if (stop.hasPendingOp)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 16, color: c.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      l.commonSavedWillSend,
                      style: text.bodySmall?.copyWith(color: c.mutedForeground),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (status == TaskStatus.inProgress)
            Text(l.driverSpraying, style: text.titleSmall?.copyWith(color: c.infoText))
          else if (stop.arrivedAt != null && status.isOpen) ...[
            Text(l.driverYoureHere, style: text.titleSmall?.copyWith(color: c.brandText)),
            const SizedBox(height: 4),
            Text(
              (asset?.tagCannotConfirm ?? false) ? l.driverTagBuffering : l.driverWaitingTag,
              style: text.bodyMedium,
            ),
          ],
          if (status.isOpen) ...[const SizedBox(height: 8), TagStatusChip(asset: asset)],
          if (stop.impact != null) ...[
            const SizedBox(height: 12),
            _VerifiedBlock(impact: stop.impact!, stop: stop),
          ] else if (status == TaskStatus.verifying || status == TaskStatus.done) ...[
            const SizedBox(height: 12),
            Text(l.driverVerifying, style: text.bodyMedium?.copyWith(color: c.mutedForeground)),
          ],
          const SizedBox(height: 24),
          if (status.isOpen) ...[
            BigActionButton(
              icon: Icons.navigation,
              label: l.commonNavigate,
              onPressed: () => NextStopHero.navigate(ref, stop),
            ),
            if (stop.arrivedAt == null && status != TaskStatus.inProgress) ...[
              const SizedBox(height: 12),
              BigActionButton(
                icon: Icons.where_to_vote_outlined,
                label: l.driverArrived,
                variant: BigActionVariant.secondary,
                onPressed: () => ref.read(stopActionsProvider.notifier).arrived(stop),
              ),
            ],
            if (canManual) ...[
              const SizedBox(height: 12),
              BigActionButton(
                icon: Icons.task_alt,
                label: l.driverMarkManual,
                variant: BigActionVariant.secondary,
                onPressed: () => context.push(Routes.stopManualDone(taskId)),
              ),
            ],
            if (status.canSkip) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push(Routes.stopSkip(taskId)),
                  icon: const Icon(Icons.block),
                  label: Text(l.driverCantDo),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// "Verified: PM10 −18 % for 90 min (range −26 to −10 %)" + method; never a bare number.
class _VerifiedBlock extends StatelessWidget {
  const _VerifiedBlock({required this.impact, required this.stop});

  final ImpactSummary impact;
  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final to = context.isHindi ? 'से' : 'to';
    final inconclusive =
        impact.verdict == ImpactVerdict.inconclusive || impact.verdict == ImpactVerdict.unknown;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (inconclusive ? c.warning : c.brand).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: inconclusive ? c.warning : c.brand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                inconclusive ? Icons.help_outline : Icons.verified,
                color: inconclusive ? c.warningText : c.brandText,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  inconclusive
                      ? l.driverInconclusive
                      : l
                            .driverVerified(
                              impact.pollutant.symbol,
                              Numbers.signed(impact.effectPct, digits: 0),
                              '${impact.durationMin ?? stop.durationMin ?? 90}',
                              Numbers.signed(impact.ciLow, digits: 0),
                              Numbers.signed(impact.ciHigh, digits: 0),
                            )
                            .replaceAll(' to ', ' $to '),
                  style: text.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l.driverMethod(impact.method.label(l)), style: text.bodyMedium),
          if (impact.method.isLowerEvidence || stop.lowerEvidence)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l.driverLowerEvidence,
                style: text.bodySmall?.copyWith(color: c.warningText),
              ),
            ),
        ],
      ),
    );
  }
}
