import 'package:drift/drift.dart';

/// Generic JSON cache: inspection bundles, air, forecast, site, report status (§3).
@DataClassName('CachedPayloadRow')
class CachedPayloadsTable extends Table {
  @override
  String get tableName => 'cached_payloads';

  TextColumn get key => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get isSimulated => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
