import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/daos/outbox_dao.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/utils/clock.dart';

/// Reconciles server task events with unsent ops (OFFLINE_AND_SYNC §7). The server is
/// authoritative; completion-source precedence is hawatag > gps_inferred > manual.
class ConflictResolver {
  ConflictResolver({required this.db, required this.clock, required this.publish});

  final AppDatabase db;
  final Clock clock;
  final void Function(ConflictNotice) publish;

  static const _completed = {'done', 'verifying', 'verified', 'inconclusive'};
  static const Set<String> _terminal = {..._completed, 'skipped', 'cancelled', 'missed', 'failed'};

  /// Call when the server reports [status] for [taskId] (WS, push or refresh). Pending ops that
  /// the new state makes pointless are superseded (never sent) and the overlay clears.
  Future<void> onServerTaskStatus(String taskId, String status, {String? source}) async {
    if (!_terminal.contains(status)) return;
    final now = clock.now().toUtc();
    final ops = await db.outboxDao.activeFor(OrderingKeys.task(taskId));
    for (final row in ops) {
      if (row.state != OutboxDao.pending) continue; // in-flight ops settle through their response
      final op = OutboxOp.fromRow(row);
      ConflictKind? notice;
      if (op.kind == OpKind.taskStatus) {
        final wanted = op.payload['status'];
        if (status == 'cancelled') {
          notice = ConflictKind.stopRemoved;
        } else if (_completed.contains(status) && wanted == 'done') {
          notice = source == 'hawatag' || source == null ? ConflictKind.tagAlreadyDone : null;
        } else if (_completed.contains(status) && wanted == 'skipped') {
          notice = ConflictKind.skipNotNeeded;
        }
      }
      await db.outboxDao.markSuperseded(op.id, code: 'server_$status', now: now);
      if (notice != null) publish(ConflictNotice(kind: notice, entityId: taskId, at: now));
    }
    await db.taskDao.setPendingStatus(taskId, null);
  }

  /// A full snapshot no longer contains [taskId]: the stop was removed by a re-plan.
  Future<void> onTaskRemoved(String taskId) => onServerTaskStatus(taskId, 'cancelled');
}
