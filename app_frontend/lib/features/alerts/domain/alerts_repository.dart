import 'package:hawa_app/features/alerts/domain/app_alert.dart';

/// Alert inbox (X1/X2): drift is the source of truth for the UI; the server fills it.
abstract interface class AlertsRepository {
  /// Newest first (by received time), at most 200 rows.
  Stream<List<AppAlert>> watchInbox();

  Stream<AppAlert?> watchAlert(String id);

  /// Last successful `GET /v1/alerts` (freshness banner).
  Stream<DateTime?> watchLastSuccess();

  /// `GET /v1/alerts` → upsert (local read/ack state is kept) and prune to 30 days / 200 rows.
  Future<void> refresh();

  /// `GET /v1/alerts/{id}` → upsert. Used when a deep link opens an alert not cached yet.
  Future<AppAlert> fetch(String id);

  /// Local only (opening the detail marks it read).
  Future<void> markRead(String id);

  /// Marks the row acknowledged and enqueues one `alert_ack` op in the same transaction.
  /// Returns false when it was already acknowledged (double tap: no second op).
  Future<bool> acknowledge(String id);

  /// Upserts an `alert.*` WebSocket event when its audience matches [activeRole].
  Future<bool> applyRealtime(
    Map<String, Object?> data, {
    required String? activeRole,
    DateTime? eventTs,
  });
}
