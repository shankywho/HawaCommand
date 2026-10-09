// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_window_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafeWindowOut _$SafeWindowOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SafeWindowOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'school_id',
            'date',
            'issued_at',
            'is_final',
            'windows',
            'advice',
            'is_simulated'
          ],
        );
        final val = SafeWindowOut(
          schoolId: $checkedConvert('school_id', (v) => v as String),
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          issuedAt:
              $checkedConvert('issued_at', (v) => DateTime.parse(v as String)),
          isFinal: $checkedConvert('is_final', (v) => v as bool),
          windows: $checkedConvert(
              'windows',
              (v) => (v as List<dynamic>)
                  .map((e) => SafeWindow.fromJson(e as Map<String, dynamic>))
                  .toList()),
          advice: $checkedConvert(
              'advice',
              (v) => $enumDecode(_$ClassroomAdviceEnumMap, v,
                  unknownValue: ClassroomAdvice.unknownDefaultOpenApi)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          adviceReason: $checkedConvert('advice_reason', (v) => v as String?),
          adviceReasonHi:
              $checkedConvert('advice_reason_hi', (v) => v as String?),
          assemblyPm25: $checkedConvert(
              'assembly_pm25',
              (v) => v == null
                  ? null
                  : QuantileValue.fromJson(v as Map<String, dynamic>)),
          alertRequired: $checkedConvert('alert_required', (v) => v as bool?),
          modelVersion: $checkedConvert('model_version', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'schoolId': 'school_id',
        'issuedAt': 'issued_at',
        'isFinal': 'is_final',
        'isSimulated': 'is_simulated',
        'adviceReason': 'advice_reason',
        'adviceReasonHi': 'advice_reason_hi',
        'assemblyPm25': 'assembly_pm25',
        'alertRequired': 'alert_required',
        'modelVersion': 'model_version'
      },
    );

Map<String, dynamic> _$SafeWindowOutToJson(SafeWindowOut instance) =>
    <String, dynamic>{
      'school_id': instance.schoolId,
      'date': instance.date.toIso8601String(),
      'issued_at': instance.issuedAt.toIso8601String(),
      'is_final': instance.isFinal,
      'windows': instance.windows.map((e) => e.toJson()).toList(),
      'advice': _$ClassroomAdviceEnumMap[instance.advice]!,
      'is_simulated': instance.isSimulated,
      if (instance.adviceReason case final value?) 'advice_reason': value,
      if (instance.adviceReasonHi case final value?) 'advice_reason_hi': value,
      if (instance.assemblyPm25?.toJson() case final value?)
        'assembly_pm25': value,
      if (instance.alertRequired case final value?) 'alert_required': value,
      if (instance.modelVersion case final value?) 'model_version': value,
    };

const _$ClassroomAdviceEnumMap = {
  ClassroomAdvice.normal: 'normal',
  ClassroomAdvice.seal: 'seal',
  ClassroomAdvice.ventilate: 'ventilate',
  ClassroomAdvice.unknownDefaultOpenApi: 'unknown_default_open_api',
};
