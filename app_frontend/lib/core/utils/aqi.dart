import 'package:hawa_app/core/utils/contract_enums.dart';

/// CPCB breakpoints (CONTRACTS §10.1). Fallback only: the server's `aqi` and `aqi_category`
/// win whenever they are present.
abstract final class Aqi {
  static const _pm25 = [
    (0.0, 30.0, 0, 50),
    (31.0, 60.0, 51, 100),
    (61.0, 90.0, 101, 200),
    (91.0, 120.0, 201, 300),
    (121.0, 250.0, 301, 400),
    (251.0, 500.0, 401, 500),
  ];
  static const _pm10 = [
    (0.0, 50.0, 0, 50),
    (51.0, 100.0, 51, 100),
    (101.0, 250.0, 101, 200),
    (251.0, 350.0, 201, 300),
    (351.0, 430.0, 301, 400),
    (431.0, 600.0, 401, 500),
  ];

  static int fromPm25(double value) => _index(_pm25, value);

  static int fromPm10(double value) => _index(_pm10, value);

  /// AQI ≤ 50 / 100 / 200 / 300 / 400 / > 400.
  static AqiCategory category(int aqi) {
    if (aqi <= 50) return AqiCategory.good;
    if (aqi <= 100) return AqiCategory.satisfactory;
    if (aqi <= 200) return AqiCategory.moderate;
    if (aqi <= 300) return AqiCategory.poor;
    if (aqi <= 400) return AqiCategory.veryPoor;
    return AqiCategory.severe;
  }

  /// GRAP stage from AQI (CONTRACTS §10.2).
  static int grapStage(int aqi) {
    if (aqi <= 200) return 0;
    if (aqi <= 300) return 1;
    if (aqi <= 400) return 2;
    if (aqi <= 450) return 3;
    return 4;
  }

  static int _index(List<(double, double, int, int)> table, double value) {
    final c = value < 0 ? 0.0 : value;
    for (var i = 0; i < table.length; i++) {
      final (lo, hi, aLo, aHi) = table[i];
      if (c <= hi || i == table.length - 1) {
        final clamped = c.clamp(lo, hi);
        return (aLo + (clamped - lo) * (aHi - aLo) / (hi - lo)).round();
      }
    }
    return 500;
  }
}

/// Roman numerals for GRAP stages (DESIGN_SYSTEM §2.4).
String grapRoman(int stage) => const ['0', 'I', 'II', 'III', 'IV'][stage.clamp(0, 4)];
