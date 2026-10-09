import 'package:drift/drift.dart';

/// Per-scope freshness, etag and the drain lease (OFFLINE_AND_SYNC §3).
@DataClassName('SyncStateRow')
class SyncStateTable extends Table {
  @override
  String get tableName => 'sync_state';

  TextColumn get scope => text()(); // tasks:2026-11-13 | alerts | outbox_drain | …
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  TextColumn get etag => text().nullable()();
  TextColumn get cursor => text().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();
  TextColumn get leaseOwner => text().nullable()();
  DateTimeColumn get leaseUntil => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {scope};
}
