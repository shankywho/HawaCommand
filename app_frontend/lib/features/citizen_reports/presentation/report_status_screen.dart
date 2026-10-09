import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/enum_labels.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/loading_skeleton.dart';
import 'package:hawa_app/core/widgets/simulated_badge.dart';
import 'package:hawa_app/features/citizen_reports/application/reports_controllers.dart';
import 'package:hawa_app/features/citizen_reports/domain/citizen_report.dart';

/// C7 Report status (`/citizen/reports/:reportId`): timeline in `ReportStatus` order and the
/// outcome (server text first, then the fallback by outcome code). Rejection is neutral.
class ReportStatusScreen extends ConsumerWidget {
  const ReportStatusScreen({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final detail = ref.watch(reportDetailProvider(reportId)).value;
    if (detail == null) return Scaffold(appBar: AppBar(), body: const LoadingSkeleton());
    final date =
        '${IstTime.shortDate(detail.createdAt, context.lang)} ${IstTime.time(detail.createdAt, context.lang)}';
    final outcome =
        detail.outcomeText?.of(context.lang) ??
        switch (detail.outcome) {
          'closed_confirmed' => l.reportOutcomeConfirmed,
          'closed_not_found' => l.reportOutcomeNotFound,
          'closed_unreachable' => l.reportOutcomeUnreachable,
          _ => null,
        };
    final rejected = detail.status == ReportStatus.rejected;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.reportTitle(date)),
        actions: [
          if (detail.isSimulated)
            const Padding(padding: EdgeInsets.only(right: 12), child: SimulatedBadge()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (detail.photo != null && detail.photo!.startsWith('asset://'))
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                detail.photo!.substring('asset://'.length),
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          if (detail.placeName != null) ...[
            const SizedBox(height: 8),
            Text(detail.placeName!.of(context.lang), style: text.titleMedium),
          ],
          const SizedBox(height: 16),
          for (final (i, t) in detail.timeline.indexed)
            _TimelineRow(entry: t, last: i == detail.timeline.length - 1),
          const Divider(height: 32),
          Text(
            l.reportOutcome.toUpperCase(),
            style: text.labelLarge?.copyWith(color: c.mutedForeground),
          ),
          const SizedBox(height: 8),
          Text(
            rejected
                ? (detail.rejectionReason?.of(context.lang) ?? l.reportRejectedNeutral)
                : outcome == null
                ? detail.status.label(l)
                : '$outcome ${detail.outcomeText == null ? l.reportThanks : ''}'.trim(),
            style: text.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.last});

  final TimelineEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(entry.status.icon, color: c.brandText, size: 22),
              if (!last) Expanded(child: Container(width: 2, color: c.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(entry.status.label(l), style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
          Text(IstTime.time(entry.at, context.lang), style: TextStyle(color: c.mutedForeground)),
        ],
      ),
    );
  }
}
