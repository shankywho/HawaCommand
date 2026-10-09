import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/connectivity_service.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/air_map/domain/pollution_grid.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'air_map_remote_source.g.dart';

/// The ML air layers: the twin grid, ranked hotspots and the city forecast.
abstract interface class AirMapRemoteSource {
  Future<PollutionGrid> grid();

  /// Raw `/v1/hotspots` payload (cached as-is).
  Future<Map<String, Object?>> hotspots();

  /// Raw `/v1/forecast` payload (cached as-is).
  Future<Map<String, Object?>> forecast();
}

/// The live backend. `/v1/twin` caps a page at 2,000 cells, so the city grid is fetched as
/// latitude strips in parallel (one probe tells the grid width and the total).
class HttpAirMapRemoteSource implements AirMapRemoteSource {
  HttpAirMapRemoteSource(this._api, [this._fallback]);

  final CommandCenterApi _api;
  final FakeAirMapRemoteSource? _fallback;

  @override
  Future<PollutionGrid> grid() async {
    try {
      final probe = await _api.twin();
      final cells = <String, Map<String, Object?>>{};
      void addAll(Map<String, Object?> page) {
        for (final c in (page['cells'] as List<Object?>?) ?? const []) {
          if (c is Map<String, Object?>) cells['${c['row']}:${c['col']}'] = c;
        }
      }

      addAll(probe);
      final total = (probe['total_cells'] as num?)?.toInt() ?? cells.length;
      final asOf =
          DateTime.tryParse(probe['timestamp'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc();
      if (cells.length < total && cells.isNotEmpty) {
        final first = PollutionGrid.fromCells(
          cells.values,
          asOf: asOf,
          isSimulated: probe['simulated'] as bool? ?? false,
        );
        final rowsPerPage = CommandCenterApi.twinPageLimit ~/ first.cols;
        final totalRows = (total / first.cols).ceil();
        final strips = <String>[];
        for (var r = first.rows; r < totalRows; r += rowsPerPage) {
          final r1 = (r + rowsPerPage - 1).clamp(r, totalRows - 1);
          // min_lat,min_lon,max_lat,max_lon with a third-of-a-cell margin (server filter is inclusive).
          final lo = first.lat0 + r * first.dLat - first.dLat / 3;
          final hi = first.lat0 + r1 * first.dLat + first.dLat / 3;
          final b = first.bounds;
          strips.add(
            '${lo.toStringAsFixed(6)},${(b.minLon - 0.01).toStringAsFixed(6)},${hi.toStringAsFixed(6)},${(b.maxLon + 0.01).toStringAsFixed(6)}',
          );
        }
        final pages = await Future.wait([for (final s in strips) _api.twin(bbox: s)]);
        pages.forEach(addAll);
      }
      return PollutionGrid.fromCells(
        cells.values,
        asOf: asOf,
        isSimulated: probe['simulated'] as bool? ?? false,
      );
    } catch (_) {
      if (_fallback != null) return _fallback.grid();
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> hotspots() async {
    try {
      final res = await _api.hotspots();
      if (res.isNotEmpty) return res;
      if (_fallback != null) return _fallback.hotspots();
      return res;
    } catch (_) {
      if (_fallback != null) return _fallback.hotspots();
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> forecast() async {
    try {
      final res = await _api.forecast();
      if (res.isNotEmpty) return res;
      if (_fallback != null) return _fallback.forecast();
      return res;
    } catch (_) {
      if (_fallback != null) return _fallback.forecast();
      rethrow;
    }
  }
}

/// Fake mode: the same ML output captured from the backend into `assets/fixtures/air_map/`,
/// re-stamped to now. Honours Dev tools "Go offline".
class FakeAirMapRemoteSource implements AirMapRemoteSource {
  FakeAirMapRemoteSource({required this.now, required this.offline, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final DateTime Function() now;
  final bool Function() offline;
  final AssetBundle _bundle;

  Future<Map<String, Object?>> _load(String name) async {
    if (offline()) throw const SimulatedOfflineFailure();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return jsonDecode(await _bundle.loadString('assets/fixtures/air_map/$name'))
        as Map<String, Object?>;
  }

  @override
  Future<PollutionGrid> grid() async {
    final json = await _load('twin_grid.json');
    return PollutionGrid.fromCompact({...json, 'timestamp': now().toUtc().toIso8601String()});
  }

  @override
  Future<Map<String, Object?>> hotspots() async => {
    ...await _load('hotspots.json'),
    'asOf': now().toUtc().toIso8601String(),
  };

  @override
  Future<Map<String, Object?>> forecast() async => {
    ...await _load('forecast.json'),
    'issuedAt': now().toUtc().toIso8601String(),
  };
}

@riverpod
AirMapRemoteSource airMapRemoteSource(Ref ref) {
  final fallback = FakeAirMapRemoteSource(
    now: ref.watch(appClockProvider).now,
    offline: () => ref.read(forcedOfflineProvider),
  );
  if (Env.isFake('air_map')) return fallback;
  return HttpAirMapRemoteSource(ref.watch(commandCenterApiProvider), fallback);
}

