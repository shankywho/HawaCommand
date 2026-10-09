import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:hawa_app/core/storage/daos/alert_dao.dart';
import 'package:hawa_app/core/storage/daos/cache_dao.dart';
import 'package:hawa_app/core/storage/daos/location_dao.dart';
import 'package:hawa_app/core/storage/daos/media_dao.dart';
import 'package:hawa_app/core/storage/daos/outbox_dao.dart';
import 'package:hawa_app/core/storage/daos/report_dao.dart';
import 'package:hawa_app/core/storage/daos/sync_state_dao.dart';
import 'package:hawa_app/core/storage/daos/task_dao.dart';
import 'package:hawa_app/core/storage/tables/alerts_table.dart';
import 'package:hawa_app/core/storage/tables/cached_payloads_table.dart';
import 'package:hawa_app/core/storage/tables/location_pings_table.dart';
import 'package:hawa_app/core/storage/tables/media_files_table.dart';
import 'package:hawa_app/core/storage/tables/outbox_ops_table.dart';
import 'package:hawa_app/core/storage/tables/reports_draft_table.dart';
import 'package:hawa_app/core/storage/tables/routes_table.dart';
import 'package:hawa_app/core/storage/tables/safe_windows_table.dart';
import 'package:hawa_app/core/storage/tables/stops_table.dart';
import 'package:hawa_app/core/storage/tables/sync_state_table.dart';
import 'package:hawa_app/core/storage/tables/tasks_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// The app's SQLite database (drift, WAL). The FCM background handler and the workmanager
/// callback open their own connection to the same file; WAL + busy_timeout make that safe.
@DriftDatabase(
  tables: [
    RoutesTable,
    TasksTable,
    StopsTable,
    AlertsTable,
    ReportsDraftTable,
    OutboxOpsTable,
    SyncStateTable,
    MediaFilesTable,
    LocationPingsTable,
    SafeWindowsTable,
    CachedPayloadsTable,
  ],
  daos: [TaskDao, AlertDao, ReportDao, OutboxDao, SyncStateDao, MediaDao, CacheDao, LocationDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens `hawa.sqlite` in the app documents directory on a background isolate.
  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final file = await databaseFile();
      return NativeDatabase.createInBackground(
        file,
        setup: (db) {
          db
            ..execute('PRAGMA journal_mode=WAL')
            ..execute('PRAGMA busy_timeout=5000');
        },
      );
    }),
  );

  /// In-memory database for tests.
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  static Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'hawa.sqlite'));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll());

  /// Logout wipe (OFFLINE_AND_SYNC §10): every row of every table.
  Future<void> wipe() => transaction(() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  });
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
}
