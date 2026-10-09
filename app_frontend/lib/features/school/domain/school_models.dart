import 'package:hawa_app/core/utils/localized_text.dart';

/// `ClassroomAdvice` (server-computed; the app never derives it).
enum ClassroomAdvice {
  normal('normal'),
  seal('seal'),
  ventilate('ventilate'),
  unknown('unknown');

  const ClassroomAdvice(this.wire);
  final String wire;

  static ClassroomAdvice fromWire(String? w) =>
      values.firstWhere((v) => v.wire == w, orElse: () => unknown);
}

class SchoolInfo {
  const SchoolInfo({
    required this.id,
    required this.name,
    required this.wardId,
    required this.forecastCellId,
    this.dayStart = '07:30',
    this.dayEnd = '13:30',
    this.isSimulated = true,
  });

  factory SchoolInfo.fromJson(Map<String, Object?> j) {
    final hours = (j['hours'] as Map<String, Object?>?) ?? const {};
    return SchoolInfo(
      id: j['school_id']! as String,
      name: LocalizedText(en: j['name'] as String? ?? '', hi: j['name_hi'] as String?),
      wardId: j['ward_id'] as String? ?? '',
      forecastCellId: j['forecast_cell_id'] as String? ?? j['cell_id'] as String? ?? '',
      dayStart: hours['day_start'] as String? ?? '07:30',
      dayEnd: hours['day_end'] as String? ?? '13:30',
      isSimulated: j['is_simulated'] as bool? ?? true,
    );
  }

  final String id;
  final LocalizedText name;
  final String wardId;
  final String forecastCellId;
  final String dayStart;
  final String dayEnd;
  final bool isSimulated;
}

class SafeWindow {
  const SafeWindow({
    required this.start,
    required this.end,
    required this.label,
    required this.p10,
    required this.p50,
    required this.p90,
    required this.confidence,
  });

  final DateTime start;
  final DateTime end;

  /// `safe` | `borderline` | `avoid`.
  final String label;
  final double? p10;
  final double? p50;
  final double? p90;
  final double confidence;
}

class SafeWindowDay {
  const SafeWindowDay({
    required this.date,
    required this.windows,
    required this.advice,
    required this.isFinal,
    this.issuedAt,
    this.adviceReason,
  });

  factory SafeWindowDay.fromJson(Map<String, Object?> j) => SafeWindowDay(
    date: j['date'] as String? ?? '',
    isFinal: j['is_final'] as bool? ?? true,
    issuedAt: DateTime.tryParse(j['issued_at'] as String? ?? '')?.toUtc(),
    advice: ClassroomAdvice.fromWire(j['advice'] as String?),
    adviceReason: j['advice_reason'] is String
        ? LocalizedText(en: j['advice_reason']! as String, hi: j['advice_reason_hi'] as String?)
        : null,
    windows: [
      for (final w in (j['windows'] as List<Object?>?) ?? const [])
        if (w is Map<String, Object?>)
          SafeWindow(
            start: DateTime.parse(w['start']! as String).toUtc(),
            end: DateTime.parse(w['end']! as String).toUtc(),
            label: w['label'] as String? ?? 'avoid',
            p10: _d(w['pm25_p10']),
            p50: _d(w['pm25_p50']),
            p90: _d(w['pm25_p90']),
            confidence: _d(w['confidence']) ?? 0,
          ),
    ],
  );

  final String date;
  final List<SafeWindow> windows;
  final ClassroomAdvice advice;
  final bool isFinal;
  final DateTime? issuedAt;
  final LocalizedText? adviceReason;

  List<SafeWindow> get safe =>
      windows.where((w) => w.label == 'safe' || w.label == 'borderline').toList();

  /// The window covering the assembly (or the first "avoid" one).
  SafeWindow? get morning => windows.isEmpty ? null : windows.first;

  static double? _d(Object? v) => v is num ? v.toDouble() : null;
}

class IndoorPoint {
  const IndoorPoint({required this.ts, this.outdoor, this.indoor, this.co2, this.ratio});

  final DateTime ts;
  final double? outdoor;
  final double? indoor;
  final double? co2;
  final double? ratio;
}

class IndoorOutdoor {
  const IndoorOutdoor({
    required this.series,
    this.advice = ClassroomAdvice.unknown,
    this.isSimulated = true,
  });

  factory IndoorOutdoor.fromJson(Map<String, Object?> j) {
    double? d(Object? v) => v is num ? v.toDouble() : null;
    return IndoorOutdoor(
      advice: ClassroomAdvice.fromWire(j['advice'] as String?),
      isSimulated: j['is_simulated'] as bool? ?? true,
      series: [
        for (final p in (j['series'] as List<Object?>?) ?? const [])
          if (p is Map<String, Object?>)
            IndoorPoint(
              ts: DateTime.parse(p['ts']! as String).toUtc(),
              outdoor: d(p['outdoor_pm25']),
              indoor: d(p['indoor_pm25']),
              co2: d(p['indoor_co2_ppm']),
              ratio: d(p['ratio_in_out']),
            ),
      ],
    );
  }

  final List<IndoorPoint> series;
  final ClassroomAdvice advice;
  final bool isSimulated;

  IndoorPoint? get latest => series.isEmpty ? null : series.last;
}

class ForecastHour {
  const ForecastHour({required this.at, required this.p50, this.p10, this.p90});

  final DateTime at;
  final double p50;
  final double? p10;
  final double? p90;
}

class CellForecast {
  const CellForecast({required this.issuedAt, required this.series, this.isSimulated = true});

  /// Contract shape: `series: [{valid_at, p10, p50, p90}]`.
  factory CellForecast.fromJson(Map<String, Object?> j) {
    double? d(Object? v) => v is num ? v.toDouble() : null;
    final issued =
        DateTime.tryParse(j['issued_at'] as String? ?? '')?.toUtc() ?? DateTime.now().toUtc();
    return CellForecast(
      issuedAt: issued,
      isSimulated: j['is_simulated'] as bool? ?? true,
      series: [
        for (final p in (j['series'] as List<Object?>?) ?? const [])
          if (p is Map<String, Object?> && d(p['p50']) != null)
            ForecastHour(
              at:
                  DateTime.tryParse(p['valid_at'] as String? ?? '')?.toUtc() ??
                  issued.add(Duration(hours: (p['horizon_h'] as num?)?.toInt() ?? 0)),
              p50: d(p['p50'])!,
              p10: d(p['p10']),
              p90: d(p['p90']),
            ),
      ],
    );
  }

  final DateTime issuedAt;
  final List<ForecastHour> series;
  final bool isSimulated;
}

class GrapDay {
  const GrapDay({required this.date, required this.stage, required this.probability});

  final String date;
  final int stage;
  final double probability;

  static List<GrapDay> listFromJson(Map<String, Object?> j) => [
    for (final d in (j['days'] as List<Object?>?) ?? const [])
      if (d is Map<String, Object?>)
        GrapDay(
          date: d['date'] as String? ?? '',
          stage: (d['stage'] as num?)?.toInt() ?? 0,
          probability: (d['probability'] as num?)?.toDouble() ?? 0,
        ),
  ];
}
