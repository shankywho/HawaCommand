import 'package:drift/drift.dart';

/// Task rows for drivers and inspectors (OFFLINE_AND_SYNC §3). Inspector targets are keyed by
/// inspection id (report-origin inspections may have no task).
@DataClassName('TaskRow')
@TableIndex(name: 'tasks_date_kind', columns: {#serviceDate, #kind})
class TasksTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text()();
  TextColumn get routeId => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('driver'))();
  TextColumn get kind => text()(); // TaskKind wire value
  TextColumn get status => text()(); // TaskStatus (server)
  TextColumn get pendingStatus => text().nullable()(); // optimistic overlay from an unsent op
  TextColumn get completionSource => text().nullable()(); // InterventionSource
  TextColumn get serviceDate => text()();
  IntColumn get sequence => integer().withDefault(const Constant(0))();
  DateTimeColumn get windowStart => dateTime()();
  DateTimeColumn get windowEnd => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get payloadJson => text()(); // full entity JSON for detail screens
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();
  DateTimeColumn get serverUpdatedAt => dateTime()();
  BoolColumn get isSimulated => boolean().withDefault(const Constant(false))();

  /// Local-only "arrived" state (geofence or the Arrived button); never sent for drivers.
  DateTimeColumn get arrivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
