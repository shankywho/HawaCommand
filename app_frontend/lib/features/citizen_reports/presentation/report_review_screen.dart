import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/router/routes.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/big_action_button.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';
import 'package:hawa_app/features/citizen_reports/application/reports_controllers.dart';
import 'package:hawa_app/features/citizen_reports/domain/citizen_report.dart';

/// C5 Report review (`/citizen/report/review?draft=`): photo, time, accuracy, category, note,
/// Send. Offline sends queue and appear in C6 as "Waiting to send".
class ReportReviewScreen extends ConsumerStatefulWidget {
  const ReportReviewScreen({required this.draftId, super.key});

  final String? draftId;

  @override
  ConsumerState<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends ConsumerState<ReportReviewScreen> {
  ReportCategory _category = ReportCategory.burning;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l = context.l10n;
    final offline = ref.read(networkStatusProvider).value?.isOffline ?? false;
    await ref
        .read(reportSenderProvider.notifier)
        .send(widget.draftId!, category: _category, note: _note.text, lang: context.lang);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(offline ? l.reviewSavedOffline : l.reviewSent)));
    context.go(Routes.myReports);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.hawaColors;
    final text = Theme.of(context).textTheme;
    final id = widget.draftId;
    final draft = id == null ? null : ref.watch(reportDraftProvider(id)).value;
    final busy = ref.watch(reportSenderProvider);
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.reviewTitle)),
        body: EmptyState(icon: Icons.photo, message: l.myReportsEmpty),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.reviewTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: draft.photoPath.isEmpty
                  ? Container(height: 220, color: c.muted)
                  : Image.file(File(draft.photoPath), height: 260, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            Text(
              '${IstTime.time(draft.capturedAt, context.lang)} · ± ${draft.accuracyM.round()} m',
              style: text.bodyMedium?.copyWith(color: c.mutedForeground),
            ),
            const SizedBox(height: 16),
            Text(l.reviewWhat, style: text.titleMedium),
            RadioGroup<ReportCategory>(
              groupValue: _category,
              onChanged: (v) => setState(() => _category = v ?? _category),
              child: Column(
                children: [
                  for (final cat in ReportCategory.values)
                    RadioListTile<ReportCategory>(
                      contentPadding: EdgeInsets.zero,
                      value: cat,
                      title: Text(switch (cat) {
                        ReportCategory.burning => l.catBurning,
                        ReportCategory.dust => l.catDust,
                        ReportCategory.other => l.catOther,
                      }),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _note,
              maxLength: 280,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l.reviewNote,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            BigActionButton(
              icon: Icons.send,
              label: l.reviewSend,
              busy: busy,
              onPressed: busy ? null : _send,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.go(Routes.reportCapture),
              icon: const Icon(Icons.replay),
              label: Text(l.reviewRetake),
            ),
          ],
        ),
      ),
    );
  }
}
