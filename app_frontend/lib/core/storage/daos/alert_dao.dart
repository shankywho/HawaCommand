import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/alerts_table.dart';

part 'alert_dao.g.dart';

/// Alert inbox: paging, read and ack state.
@DriftAccessor(tables: [AlertsTable])
class AlertDao extends DatabaseAccessor<AppDatabase> with _$AlertDaoMixin {
  AlertDao(super.attachedDatabase);

  Stream<List<AlertRow>> watchInbox({int limit = 200}) =>
      (select(alertsTable)
            ..orderBy([(a) => OrderingTerm.desc(a.receivedAt)])
            ..limit(limit))
          .watch();

  Stream<AlertRow?> watchAlert(String id) =>
      (select(alertsTable)..where((a) => a.id.equals(id))).watchSingleOrNull();

  Future<AlertRow?> getAlert(String id) =>
      (select(alertsTable)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// Unread rows for [role]'s audience (rows without an audience always count), matching the
  /// inbox filter.
  Stream<int> watchUnreadCount({String? role}) {
    final count = alertsTable.id.count();
    final query = selectOnly(alertsTable)
      ..addColumns([count])
      ..where(
        alertsTable.readAt.isNull() &
            (role == null
                ? const Constant(true)
                : alertsTable.audience.isNull() |
                      alertsTable.audience.equals('') |
                      alertsTable.audience.equals(role)),
      );
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  /// Upserts server alerts. Local `read_at`/`acked_at` are kept unless the server sends them.
  Future<void> upsertAll(List<AlertsTableCompanion> alerts) => transaction(() async {
    for (final a in alerts) {
      final old = await getAlert(a.id.value);
      await into(alertsTable).insertOnConflictUpdate(
        a.copyWith(
          readAt: a.readAt.present && a.readAt.value != null ? a.readAt : Value(old?.readAt),
          ackedAt: a.ackedAt.present && a.ackedAt.value != null ? a.ackedAt : Value(old?.ackedAt),
          receivedAt: old == null ? a.receivedAt : Value(old.receivedAt),
        ),
      );
    }
  });

  Future<void> markRead(String id, DateTime at) =>
      (update(alertsTable)..where((a) => a.id.equals(id) & a.readAt.isNull())).write(
        AlertsTableCompanion(readAt: Value(at)),
      );

  Future<void> markAcked(String id, DateTime at) =>
      (update(alertsTable)..where((a) => a.id.equals(id))).write(
        AlertsTableCompanion(ackedAt: Value(at), readAt: Value(at)),
      );

  /// Keeps the newest [keep] alerts and nothing older than [before] (30 days).
  Future<void> prune({required DateTime before, int keep = 200}) => transaction(() async {
    await (delete(alertsTable)..where((a) => a.receivedAt.isSmallerThanValue(before))).go();
    final rows = await (select(
      alertsTable,
    )..orderBy([(a) => OrderingTerm.desc(a.receivedAt)])).get();
    if (rows.length > keep) {
      final drop = rows.skip(keep).map((r) => r.id);
      await (delete(alertsTable)..where((a) => a.id.isIn(drop))).go();
    }
  });
}
