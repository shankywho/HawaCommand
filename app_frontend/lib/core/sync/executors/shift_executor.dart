import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `POST /v1/shifts/{id}/start | end` on the `asset_shift` from `tasks/mine.shift.id` (proposed).
class ShiftExecutor extends OpExecutor {
  ShiftExecutor(this.api, {required this.start});

  final MutationApi api;
  final bool start;

  @override
  OpKind get kind => start ? OpKind.shiftStart : OpKind.shiftEnd;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) {
    final location = op.payload['location'] as Map?;
    return api.shiftAction(
      op.payload['shift_id']! as String,
      start ? 'start' : 'end',
      {
        'at': op.payload['at'],
        if (location != null)
          'location': {
            'type': 'Point',
            'coordinates': [location['lon'], location['lat']],
          },
      },
      idempotencyKey: op.id,
    );
  }
}
