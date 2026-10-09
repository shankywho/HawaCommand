import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/outbox_ops_table.dart';

part 'outbox_dao.g.dart';

/// Outbox persistence (OFFLINE_AND_SYNC §5). State machine:
/// pending → in_flight → done | failed | superseded (and back to pending on retry).
@DriftAccessor(tables: [OutboxOpsTable])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.attachedDatabase);

  static const pending = 'pending';
  static const inFlight = 'in_flight';
  static const done = 'done';
  static const failed = 'failed';
  static const superseded = 'superseded';

  Future<void> insertOp(OutboxOpsTableCompanion op) => into(outboxOpsTable).insert(op);

  Future<OutboxOpRow?> getOp(String id) =>
      (select(outboxOpsTable)..where((o) => o.id.equals(id))).getSingleOrNull();

  /// Pending, in-flight and failed ops (what `/settings/sync` lists), oldest first.
  Stream<List<OutboxOpRow>> watchVisible(String userId) =>
      (select(outboxOpsTable)
            ..where(
              (o) => o.userId.equals(userId) & o.state.isIn(const [pending, inFlight, failed]),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .watch();

  /// Unsent work: pending + in_flight (the sync chip count).
  Stream<int> watchDepth(String userId) {
    final count = outboxOpsTable.id.count();
    final q = selectOnly(outboxOpsTable)
      ..addColumns([count])
      ..where(
        outboxOpsTable.userId.equals(userId) & outboxOpsTable.state.isIn(const [pending, inFlight]),
      );
    return q.map((r) => r.read(count) ?? 0).watchSingle();
  }

  Future<int> depth(String userId) => watchDepth(userId).first;

  /// Unsent ops on one ordering key (e.g. `task:<id>`), oldest first.
  Future<List<OutboxOpRow>> activeFor(String orderingKey) =>
      (select(outboxOpsTable)
            ..where(
              (o) => o.orderingKey.equals(orderingKey) & o.state.isIn(const [pending, inFlight]),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt)]))
          .get();

  /// Dedupe for one-per-entity ops (`task_ack`, `alert_ack`): anything not failed/superseded.
  Future<bool> hasLiveOp(String kind, String orderingKey) async {
    final row =
        await (select(outboxOpsTable)
              ..where(
                (o) =>
                    o.kind.equals(kind) &
                    o.orderingKey.equals(orderingKey) &
                    o.state.isIn(const [pending, inFlight, done]),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Latest-wins ops: older pending ops with the same coalesce key are superseded.
  Future<void> supersedeCoalesced(String coalesceKey, DateTime now) =>
      (update(
        outboxOpsTable,
      )..where((o) => o.coalesceKey.equals(coalesceKey) & o.state.equals(pending))).write(
        OutboxOpsTableCompanion(
          state: const Value(superseded),
          lastErrorCode: const Value('coalesced'),
          settledAt: Value(now),
        ),
      );

  /// All pending ops of [userId], by priority then age (the drainer filters readiness).
  Future<List<OutboxOpRow>> pendingOps(String userId) =>
      (select(outboxOpsTable)
            ..where((o) => o.userId.equals(userId) & o.state.equals(pending))
            ..orderBy([(o) => OrderingTerm.asc(o.priority), (o) => OrderingTerm.asc(o.createdAt)]))
          .get();

  /// Earliest unsent op on [orderingKey]: only that one may run (head-of-line per key).
  Future<OutboxOpRow?> headOf(String orderingKey) =>
      (select(outboxOpsTable)
            ..where(
              (o) => o.orderingKey.equals(orderingKey) & o.state.isIn(const [pending, inFlight]),
            )
            ..orderBy([(o) => OrderingTerm.asc(o.createdAt), (o) => OrderingTerm.asc(o.id)])
            ..limit(1))
          .getSingleOrNull();

  Future<DateTime?> nextWakeUp(String userId) async {
    final row =
        await (select(outboxOpsTable)
              ..where((o) => o.userId.equals(userId) & o.state.equals(pending))
              ..orderBy([(o) => OrderingTerm.asc(o.nextAttemptAt)])
              ..limit(1))
            .getSingleOrNull();
    return row?.nextAttemptAt;
  }

  Future<void> markInFlight(String id) =>
      _write(id, const OutboxOpsTableCompanion(state: Value(inFlight)));

  Future<void> markDone(String id, {required DateTime now, String? resultJson}) => _write(
    id,
    OutboxOpsTableCompanion(
      state: const Value(done),
      resultJson: Value(resultJson),
      settledAt: Value(now),
      lastErrorCode: const Value(null),
    ),
  );

  Future<void> markFailed(String id, {required DateTime now, String? code, int? httpStatus}) =>
      _write(
        id,
        OutboxOpsTableCompanion(
          state: const Value(failed),
          lastErrorCode: Value(code),
          lastHttpStatus: Value(httpStatus),
          settledAt: Value(now),
        ),
      );

  Future<void> markSuperseded(String id, {required DateTime now, String? code}) => _write(
    id,
    OutboxOpsTableCompanion(
      state: const Value(superseded),
      lastErrorCode: Value(code),
      settledAt: Value(now),
    ),
  );

  Future<void> reschedule(
    String id, {
    required int attempts,
    required DateTime next,
    String? code,
    int? httpStatus,
  }) => _write(
    id,
    OutboxOpsTableCompanion(
      state: const Value(pending),
      attempts: Value(attempts),
      nextAttemptAt: Value(next),
      lastErrorCode: Value(code),
      lastHttpStatus: Value(httpStatus),
    ),
  );

  /// Back to pending without consuming an attempt (offline, paused session, app killed).
  Future<void> release(String id) =>
      _write(id, const OutboxOpsTableCompanion(state: Value(pending)));

  /// Retry now (manual): pending and due immediately; a failed op gets one more chance.
  Future<void> retryNow(String id, DateTime now) => _write(
    id,
    OutboxOpsTableCompanion(
      state: const Value(pending),
      nextAttemptAt: Value(now),
      settledAt: const Value(null),
    ),
  );

  /// `in_flight` rows found at startup were interrupted; replay with the same key is safe.
  Future<int> resetInFlight() => (update(outboxOpsTable)..where((o) => o.state.equals(inFlight)))
      .write(const OutboxOpsTableCompanion(state: Value(pending)));

  /// Cleanup: done/superseded after 24 h, failed after 7 days (OFFLINE_AND_SYNC §10).
  Future<void> prune(DateTime now) async {
    await (delete(outboxOpsTable)..where(
          (o) =>
              o.state.isIn(const [done, superseded]) &
              o.settledAt.isSmallerThanValue(now.subtract(const Duration(hours: 24))),
        ))
        .go();
    await (delete(outboxOpsTable)..where(
          (o) =>
              o.state.equals(failed) &
              o.settledAt.isSmallerThanValue(now.subtract(const Duration(days: 7))),
        ))
        .go();
  }

  Future<void> deleteOp(String id) => (delete(outboxOpsTable)..where((o) => o.id.equals(id))).go();

  Future<void> _write(String id, OutboxOpsTableCompanion c) =>
      (update(outboxOpsTable)..where((o) => o.id.equals(id))).write(c);
}
