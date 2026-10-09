// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_status_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskStatusOut _$TaskStatusOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TaskStatusOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['task_id', 'status'],
        );
        final val = TaskStatusOut(
          taskId: $checkedConvert('task_id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$TaskStatusEnumMap, v,
                  unknownValue: TaskStatus.unknownDefaultOpenApi)),
          statusSource: $checkedConvert(
              'status_source',
              (v) => $enumDecodeNullable(_$InterventionSourceEnumMap, v,
                  unknownValue: InterventionSource.unknownDefaultOpenApi)),
          interventionId:
              $checkedConvert('intervention_id', (v) => v as String?),
          evidenceLevel: $checkedConvert('evidence_level', (v) => v as String?),
          verifyAfter: $checkedConvert('verify_after',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'taskId': 'task_id',
        'statusSource': 'status_source',
        'interventionId': 'intervention_id',
        'evidenceLevel': 'evidence_level',
        'verifyAfter': 'verify_after'
      },
    );

Map<String, dynamic> _$TaskStatusOutToJson(TaskStatusOut instance) =>
    <String, dynamic>{
      'task_id': instance.taskId,
      'status': _$TaskStatusEnumMap[instance.status]!,
      if (_$InterventionSourceEnumMap[instance.statusSource] case final value?)
        'status_source': value,
      if (instance.interventionId case final value?) 'intervention_id': value,
      if (instance.evidenceLevel case final value?) 'evidence_level': value,
      if (instance.verifyAfter?.toIso8601String() case final value?)
        'verify_after': value,
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

const _$InterventionSourceEnumMap = {
  InterventionSource.hawatag: 'hawatag',
  InterventionSource.manual: 'manual',
  InterventionSource.gpsInferred: 'gps_inferred',
  InterventionSource.unknownDefaultOpenApi: 'unknown_default_open_api',
};
