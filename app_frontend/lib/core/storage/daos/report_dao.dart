import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/reports_draft_table.dart';

part 'report_dao.g.dart';

/// Citizen Eyes drafts and the status of reports sent from this phone.
@DriftAccessor(tables: [ReportsDraftTable])
class ReportDao extends DatabaseAccessor<AppDatabase> with _$ReportDaoMixin {
  ReportDao(super.attachedDatabase);

  Future<void> upsertDraft(ReportsDraftTableCompanion draft) =>
      into(reportsDraftTable).insertOnConflictUpdate(draft);

  Future<ReportDraftRow?> getDraft(String clientReportId) => (select(
    reportsDraftTable,
  )..where((r) => r.clientReportId.equals(clientReportId))).getSingleOrNull();

  Stream<ReportDraftRow?> watchDraft(String clientReportId) => (select(
    reportsDraftTable,
  )..where((r) => r.clientReportId.equals(clientReportId))).watchSingleOrNull();

  /// Drafts and queued/submitted reports, newest first.
  Stream<List<ReportDraftRow>> watchAll() =>
      (select(reportsDraftTable)..orderBy([(r) => OrderingTerm.desc(r.createdAt)])).watch();

  Future<void> updateState(
    String clientReportId, {
    required String state,
    String? serverReportId,
    String? lastStatus,
    DateTime? lastStatusAt,
  }) => (update(reportsDraftTable)..where((r) => r.clientReportId.equals(clientReportId))).write(
    ReportsDraftTableCompanion(
      state: Value(state),
      serverReportId: serverReportId == null ? const Value.absent() : Value(serverReportId),
      lastStatus: lastStatus == null ? const Value.absent() : Value(lastStatus),
      lastStatusAt: lastStatusAt == null ? const Value.absent() : Value(lastStatusAt),
    ),
  );

  Future<void> deleteDraft(String clientReportId) =>
      (delete(reportsDraftTable)..where((r) => r.clientReportId.equals(clientReportId))).go();
}
