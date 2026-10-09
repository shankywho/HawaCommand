import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:logging/logging.dart';

/// A slippy-map tile coordinate.
typedef TileXY = (int z, int x, int y);

/// Corridor prefetch (ARCHITECTURE §12.4): tiles intersecting a 300 m buffer around the route at
/// z15–z16, plus the route bbox at z12–z14, hard-capped at 400 tiles. Only with a MapTiler key,
/// on Wi-Fi or with data saver off; never from OSM servers.
abstract final class CorridorPrefetcher {
  static const maxTiles = 400;
  static final _log = Logger('prefetch');

  static List<TileXY> tilesFor(List<GeoPoint> route, GeoBox? bbox, {double bufferM = 300}) {
    final tiles = <TileXY>{};
    if (bbox != null) {
      for (var z = 12; z <= 14; z++) {
        final (x0, y1) = _tile(bbox.minLat, bbox.minLon, z);
        final (x1, y0) = _tile(bbox.maxLat, bbox.maxLon, z);
        for (var x = x0; x <= x1; x++) {
          for (var y = y0; y <= y1; y++) {
            tiles.add((z, x, y));
          }
        }
      }
    }
    final dLat = bufferM / 110574.0;
    for (final pt in route) {
      final dLon = bufferM / (111320.0 * math.cos(pt.lat * math.pi / 180));
      for (var z = 15; z <= 16; z++) {
        final (x0, y1) = _tile(pt.lat - dLat, pt.lon - dLon, z);
        final (x1, y0) = _tile(pt.lat + dLat, pt.lon + dLon, z);
        for (var x = x0; x <= x1; x++) {
          for (var y = y0; y <= y1; y++) {
            tiles.add((z, x, y));
          }
        }
      }
      if (tiles.length >= maxTiles) break;
    }
    return tiles.take(maxTiles).toList();
  }

  /// Warms the tile cache through [dio] (the cached tile provider's client).
  static Future<int> prefetch(Dio dio, List<TileXY> tiles) async {
    if (!Env.hasMapKey) return 0;
    var ok = 0;
    for (final (z, x, y) in tiles) {
      final url = Env.resolvedTileUrl
          .replaceAll('{z}', '$z')
          .replaceAll('{x}', '$x')
          .replaceAll('{y}', '$y');
      try {
        await dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
        ok++;
      } on DioException catch (e) {
        _log.fine('prefetch $z/$x/$y failed: ${e.type.name}');
      }
    }
    return ok;
  }

  static (int, int) _tile(double lat, double lon, int z) {
    final n = math.pow(2, z).toDouble();
    final x = ((lon + 180) / 360 * n).floor();
    final latRad = lat * math.pi / 180;
    final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor();
    return (x, y);
  }
}
