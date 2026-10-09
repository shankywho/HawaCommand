import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';

/// `POST /v1/inspections/{id}/close {outcome, notes, evidence_keys[], closed_at, location}`:
/// the app's single close path (the backend marks a linked `inspect` task done).
class InspectionCloseExecutor extends OpExecutor {
  InspectionCloseExecutor(this.api, this.db, {this.onClosed});

  final MutationApi api;
  final AppDatabase db;

  /// Called with the inspection id and whether the server applied it (`applied: false` = the
  /// case was already closed and the late evidence was attached).
  final Future<void> Function(String inspectionId, {required bool applied})? onClosed;

  @override
  OpKind get kind => OpKind.inspectionClose;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) async {
    final p = op.payload;
    final keys = await objectKeysFor(db, p['media_ids']);
    final location = p['location'] as Map?;
    return api.closeInspection(
      p['inspection_id']! as String,
      {
        'outcome': p['outcome'],
        'notes': ?p['notes'],
        'evidence_keys': keys,
        'closed_at': p['closed_at'],
        if (location != null)
          'location': {
            'type': 'Point',
            'coordinates': [location['lon'], location['lat']],
          },
      },
      idempotencyKey: op.id,
    );
  }

  @override
  ConflictKind? conflictFor(OutboxOp op, Failure failure) =>
      failure.code == 'inspection_already_closed' ? ConflictKind.caseClosed : null;

  @override
  Future<void> onSettled(OutboxOp op, OpState state, {Map<String, Object?>? result}) async {
    if (state != OpState.done) return;
    await onClosed?.call(
      op.payload['inspection_id']! as String,
      applied: result?['applied'] != false,
    );
  }
}
