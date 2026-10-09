import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/routes_table.dart';
import 'package:hawa_app/core/storage/tables/stops_table.dart';
import 'package:hawa_app/core/storage/tables/tasks_table.dart';

part 'task_dao.g.dart';

/// Routes, tasks and stops. The local DB is the UI's source of truth (ARCHITECTURE §1).
@DriftAccessor(tables: [RoutesTable, TasksTable, StopsTable])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.attachedDatabase);

  Stream<RouteRow?> watchRoute(String role, String date) =>
      _routeQuery(role, date).watchSingleOrNull();

  Future<RouteRow?> getRoute(String role, String date) => _routeQuery(role, date).getSingleOrNull();

  /// Latest cached day for [role] (for "no route for today yet" and yesterday's summary).
  Future<RouteRow?> latestRoute(String role) =>
      (select(routesTable)
            ..where((r) => r.role.equals(role))
            ..orderBy([(r) => OrderingTerm.desc(r.serviceDate)])
            ..limit(1))
          .getSingleOrNull();

  Stream<List<TaskRow>> watchTasks(String role, String date) => _tasksQuery(role, date).watch();

  Future<List<TaskRow>> tasksFor(String role, String date) => _tasksQuery(role, date).get();

  Stream<TaskRow?> watchTask(String id) =>
      (select(tasksTable)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<TaskRow?> getTask(String id) =>
      (select(tasksTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Replaces one day's snapshot (server wins). Local-only columns (`pending_status`,
  /// `arrived_at`) survive, and rows missing from the snapshot are kept when [keepIds] has them
  /// (they still have pending outbox ops; OFFLINE_AND_SYNC §4). Returns the previous task ids.
  Future<Set<String>> replaceSnapshot({
    required RoutesTableCompanion route,
    required List<TasksTableCompanion> tasks,
    required String role,
    required String date,
    Set<String> keepIds = const {},
  }) => transaction(() async {
    final previous = await tasksFor(role, date);
    final previousById = {for (final t in previous) t.id: t};
    final routeId = route.routeId.value;
    await into(routesTable).insertOnConflictUpdate(route);
    // A route id change for the same day replaces the old header.
    await (delete(routesTable)..where(
          (r) => r.role.equals(role) & r.serviceDate.equals(date) & r.routeId.equals(routeId).not(),
        ))
        .go();
    final incoming = <String>{};
    for (final t in tasks) {
      final id = t.id.value;
      incoming.add(id);
      final old = previousById[id];
      await into(tasksTable).insertOnConflictUpdate(
        t.copyWith(
          pendingStatus: Value(old?.pendingStatus),
          arrivedAt: Value(old?.arrivedAt),
        ),
      );
    }
    final removable = previousById.keys.where(
      (id) => !incoming.contains(id) && !keepIds.contains(id),
    );
    if (removable.isNotEmpty) {
      await (delete(tasksTable)..where((t) => t.id.isIn(removable))).go();
    }
    await (delete(stopsTable)..where((s) => s.routeId.equals(routeId))).go();
    for (final t in tasks) {
      await into(stopsTable).insertOnConflictUpdate(
        StopsTableCompanion.insert(
          routeId: routeId,
          sequence: t.sequence.value,
          taskId: t.id.value,
        ),
      );
    }
    return previousById.keys.toSet();
  });

  Future<void> upsertTask(TasksTableCompanion task) => transaction(() async {
    final old = await getTask(task.id.value);
    await into(tasksTable).insertOnConflictUpdate(
      task.copyWith(pendingStatus: Value(old?.pendingStatus), arrivedAt: Value(old?.arrivedAt)),
    );
  });

  Future<void> setPendingStatus(String id, String? status) => (update(
    tasksTable,
  )..where((t) => t.id.equals(id))).write(TasksTableCompanion(pendingStatus: Value(status)));

  Future<void> setArrived(String id, DateTime? at) => (update(
    tasksTable,
  )..where((t) => t.id.equals(id))).write(TasksTableCompanion(arrivedAt: Value(at)));

  /// Applies a server-confirmed status (WS event, op response or refresh).
  Future<void> applyServerStatus(
    String id, {
    required String status,
    String? completionSource,
    String? payloadJson,
    int? version,
    DateTime? updatedAt,
    bool clearPending = false,
  }) => (update(tasksTable)..where((t) => t.id.equals(id))).write(
    TasksTableCompanion(
      status: Value(status),
      completionSource: completionSource == null ? const Value.absent() : Value(completionSource),
      payloadJson: payloadJson == null ? const Value.absent() : Value(payloadJson),
      serverVersion: version == null ? const Value.absent() : Value(version),
      serverUpdatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
      pendingStatus: clearPending ? const Value(null) : const Value.absent(),
    ),
  );

  /// Purge days older than [date] (kept 7 days for summaries).
  Future<void> deleteBefore(String date) => transaction(() async {
    final old = await (select(
      routesTable,
    )..where((r) => r.serviceDate.isSmallerThanValue(date))).get();
    for (final r in old) {
      await (delete(stopsTable)..where((s) => s.routeId.equals(r.routeId))).go();
    }
    await (delete(routesTable)..where((r) => r.serviceDate.isSmallerThanValue(date))).go();
    await (delete(tasksTable)..where((t) => t.serviceDate.isSmallerThanValue(date))).go();
  });

  SimpleSelectStatement<$RoutesTableTable, RouteRow> _routeQuery(String role, String date) =>
      select(routesTable)
        ..where((r) => r.role.equals(role) & r.serviceDate.equals(date))
        ..orderBy([(r) => OrderingTerm.desc(r.fetchedAt)])
        ..limit(1);

  SimpleSelectStatement<$TasksTableTable, TaskRow> _tasksQuery(String role, String date) =>
      select(tasksTable)
        ..where((t) => t.role.equals(role) & t.serviceDate.equals(date))
        ..orderBy([(t) => OrderingTerm.asc(t.sequence), (t) => OrderingTerm.asc(t.windowStart)]);
}
