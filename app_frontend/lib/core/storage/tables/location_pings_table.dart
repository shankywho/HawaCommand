import 'package:drift/drift.dart';

/// Shift-only positions awaiting a `location_batch` op (ARCHITECTURE §11.3).
@DataClassName('LocationPingRow')
class LocationPingsTable extends Table {
  @override
  String get tableName => 'location_pings';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get shiftLocalId => text()();
  DateTimeColumn get ts => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real()();
  RealColumn get speed => real().nullable()();
  BoolColumn get batched => boolean().withDefault(const Constant(false))();
}
