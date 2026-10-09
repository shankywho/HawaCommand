// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SeriesPoint _$SeriesPointFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SeriesPoint',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ts', 'value'],
        );
        final val = SeriesPoint(
          ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
          value: $checkedConvert('value', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$SeriesPointToJson(SeriesPoint instance) =>
    <String, dynamic>{
      'ts': instance.ts.toIso8601String(),
      'value': instance.value,
    };
