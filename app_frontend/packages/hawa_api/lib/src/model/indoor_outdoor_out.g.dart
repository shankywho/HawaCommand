// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indoor_outdoor_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndoorOutdoorOut _$IndoorOutdoorOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'IndoorOutdoorOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'school_id',
            'interval',
            'series',
            'is_simulated'
          ],
        );
        final val = IndoorOutdoorOut(
          schoolId: $checkedConvert('school_id', (v) => v as String),
          interval: $checkedConvert('interval', (v) => v as String),
          series: $checkedConvert(
              'series',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      IndoorOutdoorPoint.fromJson(e as Map<String, dynamic>))
                  .toList()),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          summary: $checkedConvert(
              'summary',
              (v) => v == null
                  ? null
                  : IndoorOutdoorSummary.fromJson(v as Map<String, dynamic>)),
          devices: $checkedConvert(
              'devices',
              (v) => v == null
                  ? null
                  : IndoorOutdoorDevices.fromJson(v as Map<String, dynamic>)),
          advice: $checkedConvert(
              'advice',
              (v) => $enumDecodeNullable(_$ClassroomAdviceEnumMap, v,
                  unknownValue: ClassroomAdvice.unknownDefaultOpenApi)),
          adviceReason: $checkedConvert('advice_reason', (v) => v as String?),
          adviceReasonHi:
              $checkedConvert('advice_reason_hi', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'schoolId': 'school_id',
        'isSimulated': 'is_simulated',
        'adviceReason': 'advice_reason',
        'adviceReasonHi': 'advice_reason_hi'
      },
    );

Map<String, dynamic> _$IndoorOutdoorOutToJson(IndoorOutdoorOut instance) =>
    <String, dynamic>{
      'school_id': instance.schoolId,
      'interval': instance.interval,
      'series': instance.series.map((e) => e.toJson()).toList(),
      'is_simulated': instance.isSimulated,
      if (instance.summary?.toJson() case final value?) 'summary': value,
      if (instance.devices?.toJson() case final value?) 'devices': value,
      if (_$ClassroomAdviceEnumMap[instance.advice] case final value?)
        'advice': value,
      if (instance.adviceReason case final value?) 'advice_reason': value,
      if (instance.adviceReasonHi case final value?) 'advice_reason_hi': value,
    };

const _$ClassroomAdviceEnumMap = {
  ClassroomAdvice.normal: 'normal',
  ClassroomAdvice.seal: 'seal',
  ClassroomAdvice.ventilate: 'ventilate',
  ClassroomAdvice.unknownDefaultOpenApi: 'unknown_default_open_api',
};
