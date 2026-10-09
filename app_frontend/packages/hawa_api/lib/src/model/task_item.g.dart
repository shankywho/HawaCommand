// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskItem _$TaskItemFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TaskItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'kind',
            'status',
            'sequence',
            'location',
            'place_name',
            'window_start',
            'window_end',
            'version',
            'updated_at',
            'is_simulated'
          ],
        );
        final val = TaskItem(
          id: $checkedConvert('id', (v) => v as String),
          kind: $checkedConvert(
              'kind',
              (v) => $enumDecode(_$TaskKindEnumMap, v,
                  unknownValue: TaskKind.unknownDefaultOpenApi)),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$TaskStatusEnumMap, v,
                  unknownValue: TaskStatus.unknownDefaultOpenApi)),
          sequence: $checkedConvert('sequence', (v) => (v as num).toInt()),
          location: $checkedConvert(
              'location', (v) => GeoPoint.fromJson(v as Map<String, dynamic>)),
          placeName: $checkedConvert('place_name',
              (v) => LocalizedText.fromJson(v as Map<String, dynamic>)),
          windowStart: $checkedConvert(
              'window_start', (v) => DateTime.parse(v as String)),
          windowEnd:
              $checkedConvert('window_end', (v) => DateTime.parse(v as String)),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          updatedAt:
              $checkedConvert('updated_at', (v) => DateTime.parse(v as String)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          planId: $checkedConvert('plan_id', (v) => v as String?),
          cellId: $checkedConvert('cell_id', (v) => v as String?),
          instructions: $checkedConvert(
              'instructions',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          targetLitres:
              $checkedConvert('target_litres', (v) => (v as num?)?.toDouble()),
          segmentLengthM: $checkedConvert(
              'segment_length_m', (v) => (v as num?)?.toDouble()),
          durationMin:
              $checkedConvert('duration_min', (v) => (v as num?)?.toInt()),
          arrivalRadiusM: $checkedConvert(
              'arrival_radius_m', (v) => (v as num?)?.toDouble()),
          causeLabel: $checkedConvert(
              'cause_label',
              (v) => $enumDecodeNullable(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          causeConf:
              $checkedConvert('cause_conf', (v) => (v as num?)?.toDouble()),
          reasonText: $checkedConvert(
              'reason_text',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          completionSource: $checkedConvert(
              'completion_source',
              (v) => $enumDecodeNullable(_$InterventionSourceEnumMap, v,
                  unknownValue: InterventionSource.unknownDefaultOpenApi)),
          interventionId:
              $checkedConvert('intervention_id', (v) => v as String?),
          litres: $checkedConvert('litres', (v) => (v as num?)?.toDouble()),
          impactSummary: $checkedConvert(
              'impact_summary',
              (v) => v == null
                  ? null
                  : ImpactSummary.fromJson(v as Map<String, dynamic>)),
          skipReason: $checkedConvert(
              'skip_reason',
              (v) => $enumDecodeNullable(_$SkipReasonEnumMap, v,
                  unknownValue: SkipReason.unknownDefaultOpenApi)),
          inspectionId: $checkedConvert('inspection_id', (v) => v as String?),
          origin: $checkedConvert(
              'origin',
              (v) => $enumDecodeNullable(_$InspectionOriginEnumMap, v,
                  unknownValue: InspectionOrigin.unknownDefaultOpenApi)),
          priority: $checkedConvert('priority', (v) => (v as num?)?.toInt()),
          hotspotId: $checkedConvert('hotspot_id', (v) => v as String?),
          reportId: $checkedConvert('report_id', (v) => v as String?),
          siteId: $checkedConvert('site_id', (v) => v as String?),
          suspectPin: $checkedConvert(
              'suspect_pin',
              (v) => v == null
                  ? null
                  : GeoPoint.fromJson(v as Map<String, dynamic>)),
          history: $checkedConvert(
              'history',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      TaskHistoryEntry.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'placeName': 'place_name',
        'windowStart': 'window_start',
        'windowEnd': 'window_end',
        'updatedAt': 'updated_at',
        'isSimulated': 'is_simulated',
        'planId': 'plan_id',
        'cellId': 'cell_id',
        'targetLitres': 'target_litres',
        'segmentLengthM': 'segment_length_m',
        'durationMin': 'duration_min',
        'arrivalRadiusM': 'arrival_radius_m',
        'causeLabel': 'cause_label',
        'causeConf': 'cause_conf',
        'reasonText': 'reason_text',
        'completionSource': 'completion_source',
        'interventionId': 'intervention_id',
        'impactSummary': 'impact_summary',
        'skipReason': 'skip_reason',
        'inspectionId': 'inspection_id',
        'hotspotId': 'hotspot_id',
        'reportId': 'report_id',
        'siteId': 'site_id',
        'suspectPin': 'suspect_pin'
      },
    );

Map<String, dynamic> _$TaskItemToJson(TaskItem instance) => <String, dynamic>{
      'id': instance.id,
      'kind': _$TaskKindEnumMap[instance.kind]!,
      'status': _$TaskStatusEnumMap[instance.status]!,
      'sequence': instance.sequence,
      'location': instance.location.toJson(),
      'place_name': instance.placeName.toJson(),
      'window_start': instance.windowStart.toIso8601String(),
      'window_end': instance.windowEnd.toIso8601String(),
      'version': instance.version,
      'updated_at': instance.updatedAt.toIso8601String(),
      'is_simulated': instance.isSimulated,
      if (instance.planId case final value?) 'plan_id': value,
      if (instance.cellId case final value?) 'cell_id': value,
      if (instance.instructions?.toJson() case final value?)
        'instructions': value,
      if (instance.targetLitres case final value?) 'target_litres': value,
      if (instance.segmentLengthM case final value?) 'segment_length_m': value,
      if (instance.durationMin case final value?) 'duration_min': value,
      if (instance.arrivalRadiusM case final value?) 'arrival_radius_m': value,
      if (_$CauseLabelEnumMap[instance.causeLabel] case final value?)
        'cause_label': value,
      if (instance.causeConf case final value?) 'cause_conf': value,
      if (instance.reasonText?.toJson() case final value?) 'reason_text': value,
      if (_$InterventionSourceEnumMap[instance.completionSource]
          case final value?)
        'completion_source': value,
      if (instance.interventionId case final value?) 'intervention_id': value,
      if (instance.litres case final value?) 'litres': value,
      if (instance.impactSummary?.toJson() case final value?)
        'impact_summary': value,
      if (_$SkipReasonEnumMap[instance.skipReason] case final value?)
        'skip_reason': value,
      if (instance.inspectionId case final value?) 'inspection_id': value,
      if (_$InspectionOriginEnumMap[instance.origin] case final value?)
        'origin': value,
      if (instance.priority case final value?) 'priority': value,
      if (instance.hotspotId case final value?) 'hotspot_id': value,
      if (instance.reportId case final value?) 'report_id': value,
      if (instance.siteId case final value?) 'site_id': value,
      if (instance.suspectPin?.toJson() case final value?) 'suspect_pin': value,
      if (instance.history?.map((e) => e.toJson()).toList() case final value?)
        'history': value,
    };

const _$TaskKindEnumMap = {
  TaskKind.spray: 'spray',
  TaskKind.sweep: 'sweep',
  TaskKind.inspect: 'inspect',
  TaskKind.protectAlert: 'protect_alert',
  TaskKind.unknownDefaultOpenApi: 'unknown_default_open_api',
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

const _$CauseLabelEnumMap = {
  CauseLabel.dust: 'dust',
  CauseLabel.traffic: 'traffic',
  CauseLabel.burning: 'burning',
  CauseLabel.regionalSmoke: 'regional_smoke',
  CauseLabel.mixed: 'mixed',
  CauseLabel.unknown: 'unknown',
  CauseLabel.unknownDefaultOpenApi: 'unknown_default_open_api',
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

const _$InspectionOriginEnumMap = {
  InspectionOrigin.report: 'report',
  InspectionOrigin.spike: 'spike',
  InspectionOrigin.hotspot: 'hotspot',
  InspectionOrigin.plan: 'plan',
  InspectionOrigin.manual: 'manual',
  InspectionOrigin.unknownDefaultOpenApi: 'unknown_default_open_api',
};
