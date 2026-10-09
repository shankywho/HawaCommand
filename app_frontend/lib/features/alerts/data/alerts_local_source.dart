import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/features/alerts/data/alert_mapper.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';

/// Drift `alerts` rows (`db.alertDao`) and the `alerts` sync scope.
class AlertsLocalSource {
  AlertsLocalSource(this.db);

  final AppDatabase db;

  static const scope = 'alerts';

  Stream<List<AppAlert>> watchInbox() =>
      db.alertDao.watchInbox().map((rows) => rows.map(AlertMapper.fromRow).toList());

  Stream<AppAlert?> watchAlert(String id) =>
      db.alertDao.watchAlert(id).map((r) => r == null ? null : AlertMapper.fromRow(r));

  Future<AppAlert?> get(String id) async {
    final row = await db.alertDao.getAlert(id);
    return row == null ? null : AlertMapper.fromRow(row);
  }

  Future<void> upsert(List<AlertsTableCompanion> rows) => db.alertDao.upsertAll(rows);

  Future<void> markRead(String id, DateTime at) => db.alertDao.markRead(id, at);

  Future<void> markAcked(String id, DateTime at) => db.alertDao.markAcked(id, at);

  Future<void> prune(DateTime before) => db.alertDao.prune(before: before);

  Stream<DateTime?> watchLastSuccess() =>
      db.syncStateDao.watch(scope).map((s) => s?.lastSuccessAt?.toUtc());

  Future<void> markSuccess(DateTime at) => db.syncStateDao.markSuccess(scope, at);

  Future<void> markAttempt(DateTime at, String errorCode) =>
      db.syncStateDao.markAttempt(scope, at, errorCode: errorCode);
}
