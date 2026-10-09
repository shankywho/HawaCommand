// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_status_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskStatusIn _$TaskStatusInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TaskStatusIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status', 'client_ts'],
        );
        final val = TaskStatusIn(
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$TaskStatusEnumMap, v,
                  unknownValue: TaskStatus.unknownDefaultOpenApi)),
          clientTs:
              $checkedConvert('client_ts', (v) => DateTime.parse(v as String)),
          source_: $checkedConvert(
              'source',
              (v) => $enumDecodeNullable(_$InterventionSourceEnumMap, v,
                  unknownValue: InterventionSource.unknownDefaultOpenApi)),
          reason: $checkedConvert(
              'reason',
              (v) => $enumDecodeNullable(_$SkipReasonEnumMap, v,
                  unknownValue: SkipReason.unknownDefaultOpenApi)),
          note: $checkedConvert('note', (v) => v as String?),
          litres: $checkedConvert('litres', (v) => (v as num?)?.toDouble()),
          s3Keys: $checkedConvert('s3_keys',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          location: $checkedConvert(
              'location',
              (v) => v == null
                  ? null
                  : GeoPoint.fromJson(v as Map<String, dynamic>)),
          accuracyM:
              $checkedConvert('accuracy_m', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientTs': 'client_ts',
        'source_': 'source',
        's3Keys': 's3_keys',
        'accuracyM': 'accuracy_m'
      },
    );

Map<String, dynamic> _$TaskStatusInToJson(TaskStatusIn instance) =>
    <String, dynamic>{
      'status': _$TaskStatusEnumMap[instance.status]!,
      'client_ts': instance.clientTs.toIso8601String(),
      if (_$InterventionSourceEnumMap[instance.source_] case final value?)
        'source': value,
      if (_$SkipReasonEnumMap[instance.reason] case final value?)
        'reason': value,
      if (instance.note case final value?) 'note': value,
      if (instance.litres case final value?) 'litres': value,
      if (instance.s3Keys case final value?) 's3_keys': value,
      if (instance.location?.toJson() case final value?) 'location': value,
      if (instance.accuracyM case final value?) 'accuracy_m': value,
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

const _$SkipReasonEnumMap = {
  SkipReason.roadBlocked: 'road_blocked',
  SkipReason.vehicleIssue: 'vehicle_issue',
  SkipReason.waterEmpty: 'water_empty',
  SkipReason.unsafe: 'unsafe',
  SkipReason.accessDenied: 'access_denied',
  SkipReason.other: 'other',
  SkipReason.unknownDefaultOpenApi: 'unknown_default_open_api',
};
