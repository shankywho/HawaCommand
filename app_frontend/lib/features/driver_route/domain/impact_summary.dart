import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';

part 'impact_summary.freezed.dart';
part 'impact_summary.g.dart';

/// Verified effect of a stop (`impact_summary` after `task.verified`): effect ± CI, method, verdict.
@freezed
abstract class ImpactSummary with _$ImpactSummary {
  const factory ImpactSummary({
    required Pollutant pollutant,
    required double effectPct,
    required double ciLow,
    required double ciHigh,
    required ImpactMethod method,
    required ImpactVerdict verdict,
    int? durationMin,
    double? ciLevel,
  }) = _ImpactSummary;

  factory ImpactSummary.fromJson(Map<String, Object?> json) => _$ImpactSummaryFromJson(json);
}
