// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastPoint _$ForecastPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ForecastPoint',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['horizon_h', 'valid_at', 'p50'],
        );
        final val = ForecastPoint(
          horizonH: $checkedConvert('horizon_h', (v) => (v as num).toInt()),
          validAt:
              $checkedConvert('valid_at', (v) => DateTime.parse(v as String)),
          p50: $checkedConvert('p50', (v) => (v as num).toDouble()),
          p10: $checkedConvert('p10', (v) => (v as num?)?.toDouble()),
          p90: $checkedConvert('p90', (v) => (v as num?)?.toDouble()),
          aqiP50: $checkedConvert('aqi_p50', (v) => (v as num?)?.toInt()),
          grapStage: $checkedConvert('grap_stage', (v) => (v as num?)?.toInt()),
          pStageUp:
              $checkedConvert('p_stage_up', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'horizonH': 'horizon_h',
        'validAt': 'valid_at',
        'aqiP50': 'aqi_p50',
        'grapStage': 'grap_stage',
        'pStageUp': 'p_stage_up'
      },
    );

Map<String, dynamic> _$ForecastPointToJson(ForecastPoint instance) =>
    <String, dynamic>{
      'horizon_h': instance.horizonH,
      'valid_at': instance.validAt.toIso8601String(),
      'p50': instance.p50,
      if (instance.p10 case final value?) 'p10': value,
      if (instance.p90 case final value?) 'p90': value,
      if (instance.aqiP50 case final value?) 'aqi_p50': value,
      if (instance.grapStage case final value?) 'grap_stage': value,
      if (instance.pStageUp case final value?) 'p_stage_up': value,
    };
