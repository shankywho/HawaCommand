import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/tables/routes_table.dart';
import 'package:hawa_app/core/storage/tables/tasks_table.dart';

/// Ordered stop projection (route_id, sequence → task_id).
@DataClassName('StopRow')
class StopsTable extends Table {
  @override
  String get tableName => 'stops';

  TextColumn get routeId => text().references(RoutesTable, #routeId)();
  IntColumn get sequence => integer()();
  TextColumn get taskId => text().references(TasksTable, #id)();

  @override
  Set<Column<Object>> get primaryKey => {routeId, sequence};
}
