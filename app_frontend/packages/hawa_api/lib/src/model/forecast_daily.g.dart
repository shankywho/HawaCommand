// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_daily.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastDaily _$ForecastDailyFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ForecastDaily',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['date'],
        );
        final val = ForecastDaily(
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          maxP50: $checkedConvert('max_p50', (v) => (v as num?)?.toDouble()),
          maxP90: $checkedConvert('max_p90', (v) => (v as num?)?.toDouble()),
          grapStage: $checkedConvert('grap_stage', (v) => (v as num?)?.toInt()),
          peakAt: $checkedConvert(
              'peak_at', (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'maxP50': 'max_p50',
        'maxP90': 'max_p90',
        'grapStage': 'grap_stage',
        'peakAt': 'peak_at'
      },
    );

Map<String, dynamic> _$ForecastDailyToJson(ForecastDaily instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      if (instance.maxP50 case final value?) 'max_p50': value,
      if (instance.maxP90 case final value?) 'max_p90': value,
      if (instance.grapStage case final value?) 'grap_stage': value,
      if (instance.peakAt?.toIso8601String() case final value?)
        'peak_at': value,
    };
