import 'dart:io';

import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'wipe_service.g.dart';

/// Logout wipe (OFFLINE_AND_SYNC §10): DB rows, `media/`, secure storage and prefs, except the
/// language choice. Map tiles are kept (not personal).
class WipeService {
  WipeService({required this.db, required this.tokens, required this.settings});

  final AppDatabase db;
  final TokenStore tokens;
  final SettingsStore settings;
  static final _log = Logger('wipe');

  Future<void> wipeAll() async {
    await db.wipe();
    await tokens.clearAll();
    await settings.clearExceptLanguage();
    await _deleteMedia();
    _log.info('local data wiped');
  }

  /// Dev tools "Reset DB": local rows only; the session stays.
  Future<void> wipeData() async {
    await db.wipe();
    await _deleteMedia();
  }

  Future<void> _deleteMedia() async {
    try {
      final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'media'));
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      _log.warning('media wipe failed', e);
    }
  }
}

@Riverpod(keepAlive: true)
WipeService wipeService(Ref ref) => WipeService(
  db: ref.watch(appDatabaseProvider),
  tokens: ref.watch(tokenStoreProvider),
  settings: ref.watch(settingsStoreProvider),
);
