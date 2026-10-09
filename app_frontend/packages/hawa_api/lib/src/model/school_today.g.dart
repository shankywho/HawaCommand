// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_today.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolToday _$SchoolTodayFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SchoolToday',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['date'],
        );
        final val = SchoolToday(
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          advice: $checkedConvert(
              'advice',
              (v) => $enumDecodeNullable(_$ClassroomAdviceEnumMap, v,
                  unknownValue: ClassroomAdvice.unknownDefaultOpenApi)),
          safeWindows: $checkedConvert(
              'safe_windows',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => SafeWindow.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {'safeWindows': 'safe_windows'},
    );

Map<String, dynamic> _$SchoolTodayToJson(SchoolToday instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      if (_$ClassroomAdviceEnumMap[instance.advice] case final value?)
        'advice': value,
      if (instance.safeWindows?.map((e) => e.toJson()).toList()
          case final value?)
        'safe_windows': value,
    };

const _$ClassroomAdviceEnumMap = {
  ClassroomAdvice.normal: 'normal',
  ClassroomAdvice.seal: 'seal',
  ClassroomAdvice.ventilate: 'ventilate',
  ClassroomAdvice.unknownDefaultOpenApi: 'unknown_default_open_api',
};
