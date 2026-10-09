// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftOut _$ShiftOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ShiftOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['shift_id', 'status'],
        );
        final val = ShiftOut(
          shiftId: $checkedConvert('shift_id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$ShiftStatusEnumMap, v,
                  unknownValue: ShiftStatus.unknownDefaultOpenApi)),
          startedAt: $checkedConvert('started_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          endedAt: $checkedConvert('ended_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'shiftId': 'shift_id',
        'startedAt': 'started_at',
        'endedAt': 'ended_at'
      },
    );

Map<String, dynamic> _$ShiftOutToJson(ShiftOut instance) => <String, dynamic>{
      'shift_id': instance.shiftId,
      'status': _$ShiftStatusEnumMap[instance.status]!,
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
