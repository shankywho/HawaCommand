import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/sync_state_table.dart';

part 'sync_state_dao.g.dart';

/// Per-scope freshness and the single-drainer lease (OFFLINE_AND_SYNC §5.6, §9).
@DriftAccessor(tables: [SyncStateTable])
class SyncStateDao extends DatabaseAccessor<AppDatabase> with _$SyncStateDaoMixin {
  SyncStateDao(super.attachedDatabase);

  static const drainScope = 'outbox_drain';

  Future<SyncStateRow?> get(String scope) =>
      (select(syncStateTable)..where((s) => s.scope.equals(scope))).getSingleOrNull();

  Stream<SyncStateRow?> watch(String scope) =>
      (select(syncStateTable)..where((s) => s.scope.equals(scope))).watchSingleOrNull();

  Future<void> markAttempt(String scope, DateTime at, {String? errorCode}) async {
    await _ensure(scope);
    await (update(syncStateTable)..where((s) => s.scope.equals(scope))).write(
      SyncStateTableCompanion(lastAttemptAt: Value(at), lastErrorCode: Value(errorCode)),
    );
  }

  Future<void> markSuccess(String scope, DateTime at, {String? etag, String? cursor}) async {
    await _ensure(scope);
    await (update(syncStateTable)..where((s) => s.scope.equals(scope))).write(
      SyncStateTableCompanion(
        lastSuccessAt: Value(at),
        lastAttemptAt: Value(at),
        lastErrorCode: const Value(null),
        etag: etag == null ? const Value.absent() : Value(etag),
        cursor: cursor == null ? const Value.absent() : Value(cursor),
        dirty: const Value(false),
      ),
    );
  }

  Future<void> setDirty(String scope, {bool dirty = true}) async {
    await _ensure(scope);
    await (update(
      syncStateTable,
    )..where((s) => s.scope.equals(scope))).write(SyncStateTableCompanion(dirty: Value(dirty)));
  }

  /// Conditional update: only one isolate drains at a time.
  Future<bool> tryAcquireLease(String owner, {required DateTime now, required Duration ttl}) async {
    await _ensure(drainScope);
    final changed = await customUpdate(
      'UPDATE sync_state SET lease_owner = ?, lease_until = ? '
      'WHERE scope = ? AND (lease_until IS NULL OR lease_until < ? OR lease_owner = ?)',
      variables: [
        Variable.withString(owner),
        Variable.withDateTime(now.add(ttl)),
        Variable.withString(drainScope),
        Variable.withDateTime(now),
        Variable.withString(owner),
      ],
      updates: {syncStateTable},
    );
    return changed > 0;
  }

  Future<void> releaseLease(String owner) => customUpdate(
    'UPDATE sync_state SET lease_owner = NULL, lease_until = NULL WHERE scope = ? AND lease_owner = ?',
    variables: [Variable.withString(drainScope), Variable.withString(owner)],
    updates: {syncStateTable},
  );

  Future<void> _ensure(String scope) => into(
    syncStateTable,
  ).insert(SyncStateTableCompanion.insert(scope: scope), mode: InsertMode.insertOrIgnore);
}
