import 'package:drift/drift.dart';

/// Alert inbox with read/ack state (OFFLINE_AND_SYNC §3).
@DataClassName('AlertRow')
@TableIndex(name: 'alerts_received', columns: {#receivedAt})
class AlertsTable extends Table {
  @override
  String get tableName => 'alerts';

  TextColumn get id => text()();
  TextColumn get kind => text()(); // AlertKind
  TextColumn get audience => text().withDefault(const Constant(''))();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get lang => text()();
  TextColumn get deepLink => text().nullable()();
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get readAt => dateTime().nullable()();
  DateTimeColumn get ackedAt => dateTime().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  BoolColumn get isSimulated => boolean().withDefault(const Constant(false))();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
