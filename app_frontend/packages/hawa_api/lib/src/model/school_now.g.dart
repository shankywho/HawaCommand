// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_now.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolNow _$SchoolNowFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SchoolNow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ts'],
        );
        final val = SchoolNow(
          ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
          outdoorPm25:
              $checkedConvert('outdoor_pm25', (v) => (v as num?)?.toDouble()),
          indoorPm25:
              $checkedConvert('indoor_pm25', (v) => (v as num?)?.toDouble()),
          indoorCo2Ppm:
              $checkedConvert('indoor_co2_ppm', (v) => (v as num?)?.toDouble()),
          ratioInOut:
              $checkedConvert('ratio_in_out', (v) => (v as num?)?.toDouble()),
          advice: $checkedConvert(
              'advice',
              (v) => $enumDecodeNullable(_$ClassroomAdviceEnumMap, v,
                  unknownValue: ClassroomAdvice.unknownDefaultOpenApi)),
        );
        return val;
      },
      fieldKeyMap: const {
        'outdoorPm25': 'outdoor_pm25',
        'indoorPm25': 'indoor_pm25',
        'indoorCo2Ppm': 'indoor_co2_ppm',
        'ratioInOut': 'ratio_in_out'
      },
    );

Map<String, dynamic> _$SchoolNowToJson(SchoolNow instance) => <String, dynamic>{
      'ts': instance.ts.toIso8601String(),
      if (instance.outdoorPm25 case final value?) 'outdoor_pm25': value,
      if (instance.indoorPm25 case final value?) 'indoor_pm25': value,
      if (instance.indoorCo2Ppm case final value?) 'indoor_co2_ppm': value,
      if (instance.ratioInOut case final value?) 'ratio_in_out': value,
      if (_$ClassroomAdviceEnumMap[instance.advice] case final value?)
        'advice': value,
    };

const _$ClassroomAdviceEnumMap = {
  ClassroomAdvice.normal: 'normal',
  ClassroomAdvice.seal: 'seal',
  ClassroomAdvice.ventilate: 'ventilate',
  ClassroomAdvice.unknownDefaultOpenApi: 'unknown_default_open_api',
};
