// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_history_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskHistoryEntry _$TaskHistoryEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TaskHistoryEntry',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status', 'at'],
        );
        final val = TaskHistoryEntry(
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$TaskStatusEnumMap, v,
                  unknownValue: TaskStatus.unknownDefaultOpenApi)),
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
          source_: $checkedConvert('source', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'source_': 'source'},
    );

Map<String, dynamic> _$TaskHistoryEntryToJson(TaskHistoryEntry instance) =>
    <String, dynamic>{
      'status': _$TaskStatusEnumMap[instance.status]!,
      'at': instance.at.toIso8601String(),
      if (instance.source_ case final value?) 'source': value,
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
