// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_ack_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskAckOut _$TaskAckOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TaskAckOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['task_id', 'status'],
        );
        final val = TaskAckOut(
          taskId: $checkedConvert('task_id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$TaskStatusEnumMap, v,
                  unknownValue: TaskStatus.unknownDefaultOpenApi)),
          acknowledgedAt: $checkedConvert('acknowledged_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskId': 'task_id',
        'acknowledgedAt': 'acknowledged_at'
      },
    );

Map<String, dynamic> _$TaskAckOutToJson(TaskAckOut instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'status': _$TaskStatusEnumMap[instance.status]!,
      if (instance.acknowledgedAt?.toIso8601String() case final value?)
        'acknowledged_at': value,
    };

const _$TaskStatusEnumMap = {
  TaskStatus.pending: 'pending',
  TaskStatus.dispatched: 'dispatched',
  TaskStatus.acknowledged: 'acknowledged',
  TaskStatus.enRoute: 'en_route',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.done: 'done',
  TaskStatus.verifying: 'verifying',
  TaskStatus.verified: 'verified',
  TaskStatus.inconclusive: 'inconclusive',
  TaskStatus.skipped: 'skipped',
  TaskStatus.cancelled: 'cancelled',
  TaskStatus.missed: 'missed',
  TaskStatus.failed: 'failed',
  TaskStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};
