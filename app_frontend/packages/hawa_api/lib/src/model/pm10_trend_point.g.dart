// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pm10_trend_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Pm10TrendPoint _$Pm10TrendPointFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Pm10TrendPoint',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['date'],
        );
        final val = Pm10TrendPoint(
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          pm10P50: $checkedConvert('pm10_p50', (v) => (v as num?)?.toDouble()),
          nObs: $checkedConvert('n_obs', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'pm10P50': 'pm10_p50', 'nObs': 'n_obs'},
    );

Map<String, dynamic> _$Pm10TrendPointToJson(Pm10TrendPoint instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      if (instance.pm10P50 case final value?) 'pm10_p50': value,
      if (instance.nObs case final value?) 'n_obs': value,
    };
