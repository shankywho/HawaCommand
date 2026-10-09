import 'package:drift/drift.dart';

/// Route header per service date and role (OFFLINE_AND_SYNC §3). Inspector days without a route
/// geometry get a local id `local:{role}:{date}` so asset and shift still have a home.
@DataClassName('RouteRow')
class RoutesTable extends Table {
  @override
  String get tableName => 'routes';

  TextColumn get routeId => text()();
  TextColumn get role => text()();
  TextColumn get serviceDate => text()(); // YYYY-MM-DD (IST)
  TextColumn get assetJson => text().nullable()(); // asset + tag status snapshot
  TextColumn get shiftJson => text().nullable()(); // shift id, status, window
  TextColumn get geometryJson => text().nullable()(); // GeoJSON LineString
  TextColumn get bboxJson => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();
  BoolColumn get isSimulated => boolean().withDefault(const Constant(false))();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {routeId};
}
