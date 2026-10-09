// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_ack_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskAckIn _$TaskAckInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TaskAckIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['at'],
        );
        final val = TaskAckIn(
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$TaskAckInToJson(TaskAckIn instance) => <String, dynamic>{
      'at': instance.at.toIso8601String(),
    };
