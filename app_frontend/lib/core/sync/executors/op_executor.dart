import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// Executes one outbox op. Throw a [Failure] on error; the drainer classifies it
/// (OFFLINE_AND_SYNC §5.5) so the rules live in one place.
abstract class OpExecutor {
  OpKind get kind;

  /// Performs the call; returns what to store in `result_json`.
  Future<Map<String, Object?>?> execute(OutboxOp op);

  /// The banner to show when this op is superseded by a conflict, if any.
  ConflictKind? conflictFor(OutboxOp op, Failure failure) => null;

  /// Local follow-up once the op settles (clear optimistic overlays, store server ids).
  Future<void> onSettled(OutboxOp op, OpState state, {Map<String, Object?>? result}) async {}
}

/// Shared helper: media ids in a payload → uploaded object keys, read at execution time.
Future<List<String>> objectKeysFor(AppDatabase db, Object? mediaIds) async {
  final ids = [for (final id in (mediaIds as List? ?? const [])) id.toString()];
  if (ids.isEmpty) return const [];
  final rows = await db.mediaDao.getMany(ids);
  final byId = {for (final r in rows) r.id: r};
  return [
    for (final id in ids)
      byId[id]?.objectKey ?? (throw const ValidationFailure([], code: 'media_not_uploaded')),
  ];
}

/// Clears a task's optimistic overlay when no other unsent op is left on its key.
Future<void> clearTaskOverlayIfIdle(
  AppDatabase db,
  String taskId, {
  required String exceptOpId,
}) async {
  final others = (await db.outboxDao.activeFor(
    OrderingKeys.task(taskId),
  )).where((o) => o.id != exceptOpId);
  if (others.isEmpty) await db.taskDao.setPendingStatus(taskId, null);
}
