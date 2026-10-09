import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/utils/clock.dart';

/// `POST /v1/reports` (JSON after presign; API.md §12 field names). `client_report_id` is the
/// natural key, so a retry after the idempotency window still creates one report.
class ReportSubmitExecutor extends OpExecutor {
  ReportSubmitExecutor(this.api, this.db, this.clock);

  final MutationApi api;
  final AppDatabase db;
  final Clock clock;

  @override
  OpKind get kind => OpKind.reportSubmit;

  @override
  Future<Map<String, Object?>?> execute(OutboxOp op) async {
    final p = op.payload;
    final keys = await objectKeysFor(db, [p['media_id']]);
    return api.createReport({
      'client_report_id': p['client_report_id'],
      'photo_key': keys.single,
      'location': {
        'type': 'Point',
        'coordinates': [p['lon'], p['lat']],
      },
      'accuracy_m': ?p['accuracy_m'],
      'captured_at': p['captured_at'],
      'category': ?p['category'],
      'note': ?p['note'],
      'lang': ?p['lang'],
    }, idempotencyKey: op.id);
  }

  @override
  Future<void> onSettled(OutboxOp op, OpState state, {Map<String, Object?>? result}) async {
    final clientId = op.payload['client_report_id']! as String;
    if (state == OpState.done) {
      await db.reportDao.updateState(
        clientId,
        state: 'submitted',
        serverReportId: result?['report_id'] as String?,
        lastStatus: (result?['status'] as String?) ?? 'submitted',
        lastStatusAt: clock.now().toUtc(),
      );
    } else if (state == OpState.failed) {
      await db.reportDao.updateState(clientId, state: 'failed');
    }
  }
}
