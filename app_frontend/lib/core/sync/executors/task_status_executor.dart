import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `POST /v1/tasks/{id}/status` with `{status, client_ts, source?, reason?, note?, litres?,
/// s3_keys?, location?, accuracy_m?}`. Photo keys are resolved from media ids at execution time.
class TaskStatusExecutor extends OpExecutor {
  TaskStatusExecutor(this.api, this.db);

  final MutationApi api;
  final AppDatabase db;

  @override
  OpKind get kind => OpKind.taskStatus;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) async {
    final p = op.payload;
    final keys = await objectKeysFor(db, p['media_ids']);
    final location = p['location'] as Map?;
    final body = <String, Object?>{
      'status': p['status'],
      'client_ts': p['client_ts'],
      'source': ?p['source'],
      'reason': ?p['reason'],
      'note': ?p['note'],
      'litres': ?p['litres'],
      if (keys.isNotEmpty) 's3_keys': keys,
      if (location != null)
        'location': {
          'type': 'Point',
          'coordinates': [location['lon'], location['lat']],
        },
      'accuracy_m': ?p['accuracy_m'],
    };
    return api.updateTaskStatus(p['task_id']! as String, body, idempotencyKey: op.id);
  }

  @override
  ConflictKind? conflictFor(OutboxOp op, Failure failure) {
    final code = failure.code;
    if (code == 'task_cancelled' || failure is NotFoundFailure) return ConflictKind.stopRemoved;
    if (code == 'task_already_done') {
      return switch (op.payload['status']) {
        'done' => ConflictKind.tagAlreadyDone,
        'skipped' => ConflictKind.skipNotNeeded,
        _ => null,
      };
    }
    return null;
  }

  @override
  Future<void> onSettled(OutboxOp op, OpState state, {Map<String, Object?>? result}) async {
    final taskId = op.taskId;
    if (taskId == null) return;
    if (state == OpState.done && result != null && result['status'] is String) {
      await db.taskDao.applyServerStatus(
        taskId,
        status: result['status']! as String,
        completionSource: result['status_source'] as String?,
      );
    }
    await clearTaskOverlayIfIdle(db, taskId, exceptOpId: op.id);
  }
}
