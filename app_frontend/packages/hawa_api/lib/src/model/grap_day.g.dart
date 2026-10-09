// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grap_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrapDay _$GrapDayFromJson(Map<String, dynamic> json) => $checkedCreate(
      'GrapDay',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['date', 'stage', 'probability'],
        );
        final val = GrapDay(
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          stage: $checkedConvert('stage', (v) => (v as num).toInt()),
          probability:
              $checkedConvert('probability', (v) => (v as num).toDouble()),
          stageProbs: $checkedConvert(
              'stage_probs',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList()),
          aqiP10: $checkedConvert('aqi_p10', (v) => (v as num?)?.toInt()),
          aqiP50: $checkedConvert('aqi_p50', (v) => (v as num?)?.toInt()),
          aqiP90: $checkedConvert('aqi_p90', (v) => (v as num?)?.toInt()),
          peakAt: $checkedConvert(
              'peak_at', (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'stageProbs': 'stage_probs',
        'aqiP10': 'aqi_p10',
        'aqiP50': 'aqi_p50',
        'aqiP90': 'aqi_p90',
        'peakAt': 'peak_at'
      },
    );

Map<String, dynamic> _$GrapDayToJson(GrapDay instance) => <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'stage': instance.stage,
      'probability': instance.probability,
      if (instance.stageProbs case final value?) 'stage_probs': value,
      if (instance.aqiP10 case final value?) 'aqi_p10': value,
      if (instance.aqiP50 case final value?) 'aqi_p50': value,
      if (instance.aqiP90 case final value?) 'aqi_p90': value,
      if (instance.peakAt?.toIso8601String() case final value?)
        'peak_at': value,
    };
