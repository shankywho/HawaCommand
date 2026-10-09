// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_shift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskShift _$TaskShiftFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TaskShift',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'status', 'start', 'end'],
        );
        final val = TaskShift(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$ShiftStatusEnumMap, v,
                  unknownValue: ShiftStatus.unknownDefaultOpenApi)),
          start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
          end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
          startedAt: $checkedConvert('started_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          endedAt: $checkedConvert('ended_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'startedAt': 'started_at', 'endedAt': 'ended_at'},
    );

Map<String, dynamic> _$TaskShiftToJson(TaskShift instance) => <String, dynamic>{
      'id': instance.id,
      'status': _$ShiftStatusEnumMap[instance.status]!,
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      if (instance.startedAt?.toIso8601String() case final value?)
        'started_at': value,
      if (instance.endedAt?.toIso8601String() case final value?)
        'ended_at': value,
    };

const _$ShiftStatusEnumMap = {
  ShiftStatus.scheduled: 'scheduled',
  ShiftStatus.active: 'active',
  ShiftStatus.ended: 'ended',
  ShiftStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};
