import 'package:drift/drift.dart';

/// School safe windows per date (F19 cache).
@DataClassName('SafeWindowRow')
class SafeWindowsTable extends Table {
  @override
  String get tableName => 'safe_windows';

  TextColumn get schoolId => text()();
  TextColumn get date => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get issuedAt => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();
  BoolColumn get isSimulated => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {schoolId, date};
}
