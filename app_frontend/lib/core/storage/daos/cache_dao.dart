import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/tables/cached_payloads_table.dart';
import 'package:hawa_app/core/storage/tables/safe_windows_table.dart';

part 'cache_dao.g.dart';

/// A cached JSON payload with its fetch time.
class CachedJson {
  const CachedJson({required this.json, required this.fetchedAt, required this.isSimulated});

  final Map<String, Object?> json;
  final DateTime fetchedAt;
  final bool isSimulated;
}

/// `cached_payloads` (generic JSON with TTL) and `safe_windows`.
@DriftAccessor(tables: [CachedPayloadsTable, SafeWindowsTable])
class CacheDao extends DatabaseAccessor<AppDatabase> with _$CacheDaoMixin {
  CacheDao(super.attachedDatabase);

  Future<CachedJson?> getJson(String key) async {
    final row = await (select(
      cachedPayloadsTable,
    )..where((c) => c.key.equals(key))).getSingleOrNull();
    return row == null ? null : _decode(row);
  }

  Stream<CachedJson?> watchJson(String key) =>
      (select(cachedPayloadsTable)..where((c) => c.key.equals(key))).watchSingleOrNull().map(
        (row) => row == null ? null : _decode(row),
      );

  Future<void> putJson(
    String key,
    Map<String, Object?> json, {
    required DateTime fetchedAt,
    DateTime? expiresAt,
    bool isSimulated = false,
  }) => into(cachedPayloadsTable).insertOnConflictUpdate(
    CachedPayloadsTableCompanion.insert(
      key: key,
      payloadJson: jsonEncode(json),
      fetchedAt: fetchedAt,
      expiresAt: Value(expiresAt),
      isSimulated: Value(isSimulated),
    ),
  );

  Future<void> deleteKey(String key) =>
      (delete(cachedPayloadsTable)..where((c) => c.key.equals(key))).go();

  Future<void> deleteExpired(DateTime now) =>
      (delete(cachedPayloadsTable)..where((c) => c.expiresAt.isSmallerThanValue(now))).go();

  Future<void> putSafeWindow({
    required String schoolId,
    required String date,
    required Map<String, Object?> json,
    required DateTime issuedAt,
    required DateTime fetchedAt,
    required bool isSimulated,
  }) => into(safeWindowsTable).insertOnConflictUpdate(
    SafeWindowsTableCompanion.insert(
      schoolId: schoolId,
      date: date,
      payloadJson: jsonEncode(json),
      issuedAt: issuedAt,
      fetchedAt: fetchedAt,
      isSimulated: Value(isSimulated),
    ),
  );

  Stream<CachedJson?> watchSafeWindow(String schoolId, String date) =>
      (select(
        safeWindowsTable,
      )..where((s) => s.schoolId.equals(schoolId) & s.date.equals(date))).watchSingleOrNull().map(
        (row) => row == null
            ? null
            : CachedJson(
                json: (jsonDecode(row.payloadJson) as Map).cast<String, Object?>(),
                fetchedAt: row.fetchedAt,
                isSimulated: row.isSimulated,
              ),
      );

  /// Safe windows for past dates are hidden and purged after 2 days.
  Future<void> deleteSafeWindowsBefore(String date) =>
      (delete(safeWindowsTable)..where((s) => s.date.isSmallerThanValue(date))).go();

  CachedJson _decode(CachedPayloadRow row) => CachedJson(
    json: (jsonDecode(row.payloadJson) as Map).cast<String, Object?>(),
    fetchedAt: row.fetchedAt,
    isSimulated: row.isSimulated,
  );
}
