import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hawa_app/app/l10n/l10n_x.dart';
import 'package:hawa_app/app/theme/hawa_colors.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/core/utils/ist_time.dart';
import 'package:hawa_app/core/widgets/confirm_sheet.dart';
import 'package:hawa_app/core/widgets/empty_state.dart';

/// X4 Pending uploads (`/settings/sync`): each queued update in words, its state, Retry now, and
/// Discard (with confirm) for permanently failed ones.
class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  static String kindLabel(OutboxOp op, AppLocalizations l) {
    final n = op.payload['sequence']?.toString();
    return switch (op.kind) {
      OpKind.taskAck => n == null ? l.opTaskGeneric : l.opTaskAck(n),
      OpKind.taskStatus => n == null ? l.opTaskGeneric : l.opTaskStatus(n),
      OpKind.inspectionClose => l.opInspectionClose,
      OpKind.photoUpload => l.opPhotoUpload,
      OpKind.reportSubmit => l.opReportSubmit,
      OpKind.alertAck => l.opAlertAck,
      OpKind.shiftStart => l.opShiftStart,
      OpKind.shiftEnd => l.opShiftEnd,
      OpKind.locationBatch => l.opLocationBatch,
      OpKind.pushToken => l.opPushToken,
      OpKind.profileUpdate => l.opProfileUpdate,
      OpKind.unknown => l.opTaskGeneric,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.hawaColors;
    final ops = ref.watch(visibleOutboxOpsProvider).value ?? const <OutboxOp>[];
    final offline = ref.watch(networkStatusProvider).value?.isOffline ?? false;
    final active = ref.watch(outboxActiveProvider).value ?? false;
    final repo = ref.read(outboxRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.syncTitle),
        actions: [
          if (ops.isNotEmpty)
            TextButton(
              onPressed: offline ? null : () => ref.read(outboxDrainerProvider).drainNow(),
              child: Text(l.settingsSendNow),
            ),
        ],
      ),
      body: ops.isEmpty
          ? EmptyState(icon: Icons.cloud_done_outlined, message: l.syncAllSent)
          : ListView.separated(
              itemCount: ops.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final op = ops[i];
                final failed = op.state == OpState.failed;
                final String status;
                if (failed) {
                  status = l.syncFailed(
                    (op.lastErrorCode ?? 'HTTP ${op.lastHttpStatus ?? '—'}').replaceAll('_', ' '),
                  );
                } else if (op.state == OpState.inFlight || active) {
                  status = l.syncSending;
                } else if (offline) {
                  status = l.syncWaiting;
                } else {
                  status = l.syncRetryingAt(IstTime.time(op.nextAttemptAt, context.lang));
                }
                return ListTile(
                  leading: Icon(
                    failed ? Icons.error_outline : Icons.schedule,
                    color: failed ? c.dangerText : c.mutedForeground,
                  ),
                  title: Text(kindLabel(op, l)),
                  subtitle: Text(status),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: () => repo.retryNow(op.id),
                        child: Text(l.syncRetryNow),
                      ),
                      if (failed)
                        TextButton(
                          onPressed: () async {
                            final ok = await showConfirmSheet(
                              context,
                              title: l.syncDiscardConfirm,
                              confirmLabel: l.syncDiscard,
                              danger: true,
                              icon: Icons.delete_outline,
                            );
                            if (ok) await repo.discard(op.id);
                          },
                          child: Text(l.syncDiscard),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
