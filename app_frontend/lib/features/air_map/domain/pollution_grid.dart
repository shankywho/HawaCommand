import 'dart:math' as math;
import 'dart:typed_data';

import 'package:hawa_app/core/utils/geo.dart';

/// One twin cell, for the tap sheet.
class GridCellInfo {
  const GridCellInfo({
    required this.cellId,
    required this.center,
    required this.pm25,
    required this.pm10,
    required this.confidence,
    this.ward,
  });

  final String cellId;
  final GeoPoint center;
  final double pm25;
  final double? pm10;
  final double confidence;
  final String? ward;
}

/// The backend's ML digital twin: 500 m cells on a regular lat/lon grid with PM2.5/PM10 estimates
/// and a confidence. Row 0 is the southern edge. Missing cells are NaN.
class PollutionGrid {
  PollutionGrid({
    required this.lat0,
    required this.lon0,
    required this.dLat,
    required this.dLon,
    required this.rows,
    required this.cols,
    required this.pm25,
    required this.pm10,
    required this.confidence,
    required this.wards,
    required this.asOf,
    required this.isSimulated,
  }) : assert(pm25.length == rows * cols, 'grid size');

  /// From `/v1/twin` cells (`row`, `col`, `latitude`, `longitude`, `pm25_est`, `pm10_est`,
  /// `confidence`, `ward`), possibly merged from several bbox pages.
  factory PollutionGrid.fromCells(
    Iterable<Map<String, Object?>> cells, {
    required DateTime asOf,
    bool isSimulated = false,
  }) {
    final list = cells
        .where((c) => c['row'] is num && c['col'] is num && c['latitude'] is num)
        .toList();
    if (list.isEmpty) throw const FormatException('twin: no cells');
    var maxRow = 0;
    var maxCol = 0;
    for (final c in list) {
      maxRow = math.max(maxRow, (c['row']! as num).toInt());
      maxCol = math.max(maxCol, (c['col']! as num).toInt());
    }
    final rows = maxRow + 1;
    final cols = maxCol + 1;
    // Grid steps from two cells that differ in row (col); fall back to ~500 m.
    double? dLat;
    double? dLon;
    final a = list.first;
    for (final c in list) {
      final dr = (c['row']! as num) - (a['row']! as num);
      final dc = (c['col']! as num) - (a['col']! as num);
      if (dLat == null && dr != 0) dLat = ((c['latitude']! as num) - (a['latitude']! as num)) / dr;
      if (dLon == null && dc != 0) {
        dLon = ((c['longitude']! as num) - (a['longitude']! as num)) / dc;
      }
      if (dLat != null && dLon != null) break;
    }
    dLat ??= 0.0045;
    dLon ??= 0.0051;
    final lat0 = (a['latitude']! as num).toDouble() - (a['row']! as num) * dLat;
    final lon0 = (a['longitude']! as num).toDouble() - (a['col']! as num) * dLon;
    final n = rows * cols;
    final pm25 = Float32List(n)..fillRange(0, n, double.nan);
    final pm10 = Float32List(n)..fillRange(0, n, double.nan);
    final conf = Float32List(n);
    final wards = List<String?>.filled(n, null);
    for (final c in list) {
      final i = (c['row']! as num).toInt() * cols + (c['col']! as num).toInt();
      final v = c['pm25_est'] ?? c['pm25'];
      if (v is num) pm25[i] = v.toDouble();
      final v10 = c['pm10_est'] ?? c['pm10'];
      if (v10 is num) pm10[i] = v10.toDouble();
      final cf = c['confidence'];
      conf[i] = cf is num ? cf.toDouble() : 0.5;
      wards[i] = c['ward'] as String?;
    }
    return PollutionGrid(
      lat0: lat0,
      lon0: lon0,
      dLat: dLat,
      dLon: dLon,
      rows: rows,
      cols: cols,
      pm25: pm25,
      pm10: pm10,
      confidence: conf,
      wards: wards,
      asOf: asOf,
      isSimulated: isSimulated,
    );
  }

  /// The compact cache/fixture form (see [toCompact]).
  factory PollutionGrid.fromCompact(Map<String, Object?> json) {
    final rows = (json['rows']! as num).toInt();
    final cols = (json['cols']! as num).toInt();
    Float32List floats(String key, double missing) {
      final raw = (json[key] as List<Object?>?) ?? const [];
      final out = Float32List(rows * cols)..fillRange(0, rows * cols, missing);
      for (var i = 0; i < raw.length && i < out.length; i++) {
        final v = raw[i];
        if (v is num) out[i] = v.toDouble();
      }
      return out;
    }

    final wardsRaw = (json['ward'] as List<Object?>?) ?? const [];
    return PollutionGrid(
      lat0: (json['lat0']! as num).toDouble(),
      lon0: (json['lon0']! as num).toDouble(),
      dLat: (json['dlat']! as num).toDouble(),
      dLon: (json['dlon']! as num).toDouble(),
      rows: rows,
      cols: cols,
      pm25: floats('pm25', double.nan),
      pm10: floats('pm10', double.nan),
      confidence: floats('conf', 0.5),
      wards: [
        for (var i = 0; i < rows * cols; i++) i < wardsRaw.length ? wardsRaw[i] as String? : null,
      ],
      asOf:
          DateTime.tryParse(json['timestamp'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc(),
      isSimulated: json['simulated'] as bool? ?? false,
    );
  }

  /// Centre of cell (0, 0).
  final double lat0;
  final double lon0;
  final double dLat;
  final double dLon;
  final int rows;
  final int cols;
  final Float32List pm25;
  final Float32List pm10;
  final Float32List confidence;
  final List<String?> wards;
  final DateTime asOf;
  final bool isSimulated;

  Map<String, Object?> toCompact() {
    double? r1(double v) => v.isNaN ? null : (v * 10).roundToDouble() / 10;
    return {
      'timestamp': asOf.toIso8601String(),
      'simulated': isSimulated,
      'lat0': lat0,
      'lon0': lon0,
      'dlat': dLat,
      'dlon': dLon,
      'rows': rows,
      'cols': cols,
      'pm25': [for (final v in pm25) r1(v)],
      'pm10': [for (final v in pm10) r1(v)],
      'conf': [for (final v in confidence) (v * 100).roundToDouble() / 100],
      'ward': wards,
    };
  }

  /// Outer edges of the grid.
  GeoBox get bounds => GeoBox(
    minLon: lon0 - dLon / 2,
    minLat: lat0 - dLat / 2,
    maxLon: lon0 + (cols - 0.5) * dLon,
    maxLat: lat0 + (rows - 0.5) * dLat,
  );

  bool contains(GeoPoint p) {
    final b = bounds;
    return p.lat >= b.minLat && p.lat <= b.maxLat && p.lon >= b.minLon && p.lon <= b.maxLon;
  }

  double valueAt(int row, int col) => pm25[row * cols + col];

  String cellIdOf(int row, int col) =>
      'G-${row.toString().padLeft(3, '0')}-${col.toString().padLeft(3, '0')}';

  /// The cell containing [p], or null outside the grid or on a missing cell.
  GridCellInfo? cellAt(GeoPoint p) {
    if (!contains(p)) return null;
    final row = ((p.lat - lat0) / dLat).round().clamp(0, rows - 1);
    final col = ((p.lon - lon0) / dLon).round().clamp(0, cols - 1);
    final i = row * cols + col;
    if (pm25[i].isNaN) return null;
    return GridCellInfo(
      cellId: cellIdOf(row, col),
      center: GeoPoint(lat: lat0 + row * dLat, lon: lon0 + col * dLon),
      pm25: pm25[i],
      pm10: pm10[i].isNaN ? null : pm10[i],
      confidence: confidence[i],
      ward: wards[i],
    );
  }

  /// Bilinear PM2.5 between cell centres; null outside the grid.
  double? pm25At(GeoPoint p) {
    if (!contains(p)) return null;
    final fr = ((p.lat - lat0) / dLat).clamp(0.0, rows - 1.0);
    final fc = ((p.lon - lon0) / dLon).clamp(0.0, cols - 1.0);
    final r0 = fr.floor();
    final c0 = fc.floor();
    final r1 = math.min(r0 + 1, rows - 1);
    final c1 = math.min(c0 + 1, cols - 1);
    final tr = fr - r0;
    final tc = fc - c0;
    var sum = 0.0;
    var weight = 0.0;
    void add(int r, int c, double w) {
      final v = pm25[r * cols + c];
      if (!v.isNaN && w > 0) {
        sum += v * w;
        weight += w;
      }
    }

    add(r0, c0, (1 - tr) * (1 - tc));
    add(r0, c1, (1 - tr) * tc);
    add(r1, c0, tr * (1 - tc));
    add(r1, c1, tr * tc);
    if (weight == 0) return null;
    return sum / weight;
  }

  /// Mean confidence of the cells (for the uncertainty copy).
  double get meanConfidence {
    var s = 0.0;
    var n = 0;
    for (var i = 0; i < confidence.length; i++) {
      if (pm25[i].isNaN) continue;
      s += confidence[i];
      n++;
    }
    return n == 0 ? 0 : s / n;
  }

  /// The [lo] and [hi] quantiles (0–1) of the PM2.5 cells: the "compare across the city" scale.
  (double, double) quantiles(double lo, double hi) {
    final values = [
      for (final v in pm25)
        if (!v.isNaN) v,
    ]..sort();
    if (values.isEmpty) return (0, 0);
    double at(double q) => values[((values.length - 1) * q).round().clamp(0, values.length - 1)];
    return (at(lo), at(hi));
  }

  (double min, double max) get pm25Range {
    var lo = double.infinity;
    var hi = double.negativeInfinity;
    for (final v in pm25) {
      if (v.isNaN) continue;
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }
    return lo.isFinite ? (lo, hi) : (0, 0);
  }
}
