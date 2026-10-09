import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/confidence_chip.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/core/widgets/stale_banner.dart';
import 'package:hawa_app/features/inspector/application/inspector_controllers.dart';
import 'package:hawa_app/features/inspector/domain/inspection_target.dart';
import 'package:hawa_app/features/shell/presentation/widgets/shell_app_bar.dart';

/// "From citizen report, 06:44" etc.
String originLine(InspectionTarget t, AppLocalizations l, String lang) => switch (t.origin) {
  InspectionOrigin.report => l.inspectorFromReport(IstTime.time(t.createdAt, lang)),
  InspectionOrigin.hotspot => l.inspectorFromHotspot,
  InspectionOrigin.spike => l.inspectorFromSpike,
  InspectionOrigin.plan => l.inspectorFromPlan,
  InspectionOrigin.manual => l.inspectorFromManual,
  InspectionOrigin.unknown => l.inspectorFromHotspot,
};

/// I1 Targets (`/inspector`): "a target, not an area", most urgent first. Cause is icon + label
/// and always appears with its confidence.
class TargetsScreen extends ConsumerWidget {
  const TargetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final targets = ref.watch(inspectionTargetsProvider);
    final fetchedAt = ref.watch(targetsFetchedAtProvider).value;
    final error = ref.watch(targetsRefreshProvider);
    return Scaffold(
      appBar: ShellAppBar(title: l.inspectorTitle),
      body: targets.when(
        loading: () => const LoadingSkeleton(),
        error: (_, _) => EmptyState(icon: Icons.cloud_off, message: l.commonSomethingWrong),
        data: (items) => RefreshIndicator(
          onRefresh: ref.read(targetsRefreshProvider.notifier).refresh,
          child: ListView(
            children: [
              FreshnessBanner(
                lastSuccess: fetchedAt,
                staleAfter: const Duration(minutes: 15),
                error: error,
                onRetry: ref.read(targetsRefreshProvider.notifier).refresh,
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: EmptyState(icon: Icons.task_alt, message: l.inspectorEmpty),
                )
              else
                for (final t in items) _TargetCard(target: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.target});

  final InspectionTarget target;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final t = target;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: InkWell(
        onTap: () => context.push(Routes.target(t.id)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(t.cause.icon, color: t.priority <= 2 ? c.dangerText : c.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.inspectorLikely(t.cause.label(l).toLowerCase()),
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (t.isSimulated) const SimulatedBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(t.placeName.of(context.lang), style: text.bodyLarge),
                    const SizedBox(height: 6),
                    ConfidenceChip(value: t.causeConf),
                    const SizedBox(height: 4),
                    Text(
                      originLine(t, l, context.lang),
                      style: text.bodySmall?.copyWith(color: c.mutedForeground),
                    ),
                    if (t.onSiteLocal || t.status == InspectionStatus.onSite)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l.inspectorOnSite,
                          style: text.labelLarge?.copyWith(color: c.brandText),
                        ),
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
