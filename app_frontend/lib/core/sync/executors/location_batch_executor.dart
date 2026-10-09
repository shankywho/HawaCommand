import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `POST /v1/shifts/{id}/locations` (proposed). Only for inspection-team shifts or while the
/// HawaTag is offline; batches older than 6 h expire instead of being sent (ARCHITECTURE §11.3).
class LocationBatchExecutor extends OpExecutor {
  LocationBatchExecutor(this.api);

  final MutationApi api;

  @override
  OpKind get kind => OpKind.locationBatch;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) => api.postLocations(
    op.payload['shift_id']! as String,
    {'pings': op.payload['pings']},
    idempotencyKey: op.id,
  );
}
