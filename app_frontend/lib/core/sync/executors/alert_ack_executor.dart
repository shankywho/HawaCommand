import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `POST /v1/alerts/{id}/ack` (proposed). A 404 (expired/deleted alert) is superseded silently.
class AlertAckExecutor extends OpExecutor {
  AlertAckExecutor(this.api);

  final MutationApi api;

  @override
  OpKind get kind => OpKind.alertAck;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) => api.ackAlert(
    op.payload['alert_id']! as String,
    at: DateTime.parse(op.payload['at']! as String),
    idempotencyKey: op.id,
  );
}
