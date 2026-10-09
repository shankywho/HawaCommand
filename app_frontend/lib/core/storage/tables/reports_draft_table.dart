import 'package:drift/drift.dart';

/// Citizen Eyes drafts and submitted-report tracking (OFFLINE_AND_SYNC §3).
@DataClassName('ReportDraftRow')
class ReportsDraftTable extends Table {
  @override
  String get tableName => 'reports_draft';

  TextColumn get clientReportId => text()(); // UUIDv7, also sent to the server
  TextColumn get mediaIdsJson => text()(); // media_files ids
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real()();
  TextColumn get locationQuality => text()(); // precise | coarse
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get category => text()(); // ReportCategory
  TextColumn get note => text().nullable()();
  TextColumn get state => text()(); // draft | queued | submitted
  TextColumn get serverReportId => text().nullable()();
  TextColumn get lastStatus => text().nullable()(); // ReportStatus
  DateTimeColumn get lastStatusAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {clientReportId};
}
