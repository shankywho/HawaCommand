import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `POST /v1/tasks/{id}/ack`.
class TaskAckExecutor extends OpExecutor {
  TaskAckExecutor(this.api, this.db);

  final MutationApi api;
  final AppDatabase db;

  @override
  OpKind get kind => OpKind.taskAck;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) => api.ackTask(
    op.payload['task_id']! as String,
    at: DateTime.parse(op.payload['at']! as String),
    idempotencyKey: op.id,
  );

  @override
  Future<void> onSettled(OutboxOp op, OpState state, {Map<String, Object?>? result}) async {
    final taskId = op.taskId;
    if (taskId == null) return;
    final task = await db.taskDao.getTask(taskId);
    if (state == OpState.done && task?.status == 'dispatched') {
      await db.taskDao.applyServerStatus(taskId, status: 'acknowledged');
    }
    await clearTaskOverlayIfIdle(db, taskId, exceptOpId: op.id);
  }
}
