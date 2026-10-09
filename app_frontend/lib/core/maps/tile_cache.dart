import 'dart:io';

import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:http_cache_file_store/http_cache_file_store.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tile_cache.g.dart';

/// Tile cache under the app support dir `tiles/` (ARCHITECTURE §12.4): served offline up to 30
/// days stale; LRU by file mtime with a 100 MB cap (40 MB with data saver).
class TileCache {
  TileCache(this.directory);

  final String directory;
  static final _log = Logger('tiles');

  static Future<TileCache> open() async {
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'tiles'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return TileCache(dir.path);
  }

  CachedTileProvider provider() =>
      CachedTileProvider(store: FileCacheStore(directory), maxStale: const Duration(days: 30));

  /// Evicts tiles older than 30 days first, then the least recently written until under [maxBytes].
  Future<void> enforceCap({required int maxBytes}) async {
    try {
      final files = <File>[];
      await for (final e in Directory(directory).list(recursive: true)) {
        if (e is File) files.add(e);
      }
      final now = DateTime.now();
      final stats = <File, FileStat>{for (final f in files) f: f.statSync()};
      var total = 0;
      for (final s in stats.values) {
        total += s.size;
      }
      final ordered = stats.entries.toList()
        ..sort((a, b) => a.value.modified.compareTo(b.value.modified));
      for (final e in ordered) {
        final old = now.difference(e.value.modified) > const Duration(days: 30);
        if (!old && total <= maxBytes) break;
        total -= e.value.size;
        await e.key.delete();
      }
    } on FileSystemException catch (e) {
      _log.warning('tile cap failed', e);
    }
  }
}

@Riverpod(keepAlive: true)
Future<TileCache> tileCache(Ref ref) => TileCache.open();
