import 'package:drift/drift.dart';

/// Pending mutations (OFFLINE_AND_SYNC §5). `id` is the UUIDv7 `Idempotency-Key`.
@DataClassName('OutboxOpRow')
@TableIndex(name: 'outbox_state_next', columns: {#state, #nextAttemptAt})
@TableIndex(name: 'outbox_ordering', columns: {#orderingKey, #createdAt})
class OutboxOpsTable extends Table {
  @override
  String get tableName => 'outbox_ops';

  TextColumn get id => text()();
  TextColumn get userId => text()(); // owner; ops never cross users
  TextColumn get kind => text()(); // OpKind
  TextColumn get orderingKey => text()(); // e.g. task:<id>
  TextColumn get dependsOn => text().nullable()(); // op id that must be done first
  TextColumn get coalesceKey => text().nullable()(); // latest-wins ops
  IntColumn get priority => integer()(); // 1 highest
  TextColumn get payloadJson => text()(); // immutable once enqueued
  TextColumn get state => text()(); // pending | in_flight | done | failed | superseded
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  IntColumn get lastHttpStatus => integer().nullable()();
  TextColumn get resultJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get clientTs => dateTime()(); // when the user acted
  DateTimeColumn get settledAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
