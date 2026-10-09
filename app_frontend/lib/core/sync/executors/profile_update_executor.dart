import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `PATCH /v1/me` (`field: me`) and `PUT /v1/me/alert-subscription` (`field: alert_subscription`),
/// both proposed. Latest wins per field.
class ProfileUpdateExecutor extends OpExecutor {
  ProfileUpdateExecutor(this.api);

  final MutationApi api;

  @override
  OpKind get kind => OpKind.profileUpdate;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) {
    final body = (op.payload['body']! as Map).cast<String, Object?>();
    return switch (op.payload['field']) {
      'alert_subscription' => api.putAlertSubscription(body, idempotencyKey: op.id),
      _ => api.patchMe(body, idempotencyKey: op.id),
    };
  }
}
