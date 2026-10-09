// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'impact_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImpactSummary _$ImpactSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ImpactSummary',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'pollutant',
            'effect_pct',
            'ci_low',
            'ci_high',
            'method',
            'verdict'
          ],
        );
        final val = ImpactSummary(
          pollutant: $checkedConvert(
              'pollutant',
              (v) => $enumDecode(_$PollutantEnumMap, v,
                  unknownValue: Pollutant.unknownDefaultOpenApi)),
          effectPct:
              $checkedConvert('effect_pct', (v) => (v as num).toDouble()),
          ciLow: $checkedConvert('ci_low', (v) => (v as num).toDouble()),
          ciHigh: $checkedConvert('ci_high', (v) => (v as num).toDouble()),
          method: $checkedConvert(
              'method',
              (v) => $enumDecode(_$ImpactMethodEnumMap, v,
                  unknownValue: ImpactMethod.unknownDefaultOpenApi)),
          verdict: $checkedConvert(
              'verdict',
              (v) => $enumDecode(_$ImpactVerdictEnumMap, v,
                  unknownValue: ImpactVerdict.unknownDefaultOpenApi)),
          durationMin:
              $checkedConvert('duration_min', (v) => (v as num?)?.toInt()),
          ciLevel: $checkedConvert('ci_level', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'effectPct': 'effect_pct',
        'ciLow': 'ci_low',
        'ciHigh': 'ci_high',
        'durationMin': 'duration_min',
        'ciLevel': 'ci_level'
      },
    );

Map<String, dynamic> _$ImpactSummaryToJson(ImpactSummary instance) =>
    <String, dynamic>{
      'pollutant': _$PollutantEnumMap[instance.pollutant]!,
      'effect_pct': instance.effectPct,
      'ci_low': instance.ciLow,
      'ci_high': instance.ciHigh,
      'method': _$ImpactMethodEnumMap[instance.method]!,
      'verdict': _$ImpactVerdictEnumMap[instance.verdict]!,
      if (instance.durationMin case final value?) 'duration_min': value,
      if (instance.ciLevel case final value?) 'ci_level': value,
    };

const _$PollutantEnumMap = {
  Pollutant.pm1: 'pm1',
  Pollutant.pm25: 'pm25',
  Pollutant.pm10: 'pm10',
  Pollutant.no2: 'no2',
  Pollutant.co: 'co',
  Pollutant.nh3: 'nh3',
  Pollutant.voc: 'voc',
  Pollutant.co2: 'co2',
  Pollutant.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$ImpactMethodEnumMap = {
  ImpactMethod.syntheticControl: 'synthetic_control',
  ImpactMethod.diffInDiff: 'diff_in_diff',
  ImpactMethod.beforeAfterNaive: 'before_after_naive',
  ImpactMethod.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$ImpactVerdictEnumMap = {
  ImpactVerdict.effective: 'effective',
  ImpactVerdict.noDetectableEffect: 'no_detectable_effect',
  ImpactVerdict.inconclusive: 'inconclusive',
  ImpactVerdict.adverse: 'adverse',
  ImpactVerdict.unknownDefaultOpenApi: 'unknown_default_open_api',
};
