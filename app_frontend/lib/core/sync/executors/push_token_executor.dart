import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `PUT /v1/me/push-token` (latest wins through the coalesce key).
class PushTokenExecutor extends OpExecutor {
  PushTokenExecutor(this.api);

  final MutationApi api;

  @override
  OpKind get kind => OpKind.pushToken;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) => api.putPushToken(op.payload);
}
