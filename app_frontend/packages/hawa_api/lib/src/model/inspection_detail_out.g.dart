// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_detail_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionDetailOut _$InspectionDetailOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InspectionDetailOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'status',
            'origin',
            'priority',
            'cause_label',
            'cause_conf',
            'suspect_pin',
            'photos',
            'is_simulated'
          ],
        );
        final val = InspectionDetailOut(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$InspectionStatusEnumMap, v,
                  unknownValue: InspectionStatus.unknownDefaultOpenApi)),
          origin: $checkedConvert(
              'origin',
              (v) => $enumDecode(_$InspectionOriginEnumMap, v,
                  unknownValue: InspectionOrigin.unknownDefaultOpenApi)),
          priority: $checkedConvert('priority', (v) => (v as num).toInt()),
          causeLabel: $checkedConvert(
              'cause_label',
              (v) => $enumDecode(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          causeConf:
              $checkedConvert('cause_conf', (v) => (v as num).toDouble()),
          suspectPin: $checkedConvert('suspect_pin',
              (v) => GeoPoint.fromJson(v as Map<String, dynamic>)),
          photos: $checkedConvert(
              'photos',
              (v) => (v as List<dynamic>)
                  .map((e) => EvidencePhoto.fromJson(e as Map<String, dynamic>))
                  .toList()),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          taskId: $checkedConvert('task_id', (v) => v as String?),
          reportId: $checkedConvert('report_id', (v) => v as String?),
          hotspotId: $checkedConvert('hotspot_id', (v) => v as String?),
          siteId: $checkedConvert('site_id', (v) => v as String?),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          suspectRadiusM: $checkedConvert(
              'suspect_radius_m', (v) => (v as num?)?.toDouble()),
          backTrajectory: $checkedConvert(
              'back_trajectory',
              (v) => v == null
                  ? null
                  : GeoLineString.fromJson(v as Map<String, dynamic>)),
          spike: $checkedConvert(
              'spike',
              (v) => v == null
                  ? null
                  : SpikeEvidence.fromJson(v as Map<String, dynamic>)),
          reporter: $checkedConvert(
              'reporter',
              (v) => v == null
                  ? null
                  : Reporter.fromJson(v as Map<String, dynamic>)),
          createdAt: $checkedConvert('created_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          reportedAt: $checkedConvert('reported_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'causeLabel': 'cause_label',
        'causeConf': 'cause_conf',
        'suspectPin': 'suspect_pin',
        'isSimulated': 'is_simulated',
        'taskId': 'task_id',
        'reportId': 'report_id',
        'hotspotId': 'hotspot_id',
        'siteId': 'site_id',
        'placeName': 'place_name',
        'suspectRadiusM': 'suspect_radius_m',
        'backTrajectory': 'back_trajectory',
        'createdAt': 'created_at',
        'reportedAt': 'reported_at'
      },
    );

Map<String, dynamic> _$InspectionDetailOutToJson(
        InspectionDetailOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$InspectionStatusEnumMap[instance.status]!,
      'origin': _$InspectionOriginEnumMap[instance.origin]!,
      'priority': instance.priority,
      'cause_label': _$CauseLabelEnumMap[instance.causeLabel]!,
      'cause_conf': instance.causeConf,
      'suspect_pin': instance.suspectPin.toJson(),
      'photos': instance.photos.map((e) => e.toJson()).toList(),
      'is_simulated': instance.isSimulated,
      if (instance.taskId case final value?) 'task_id': value,
      if (instance.reportId case final value?) 'report_id': value,
      if (instance.hotspotId case final value?) 'hotspot_id': value,
      if (instance.siteId case final value?) 'site_id': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
      if (instance.suspectRadiusM case final value?) 'suspect_radius_m': value,
      if (instance.backTrajectory?.toJson() case final value?)
        'back_trajectory': value,
      if (instance.spike?.toJson() case final value?) 'spike': value,
      if (instance.reporter?.toJson() case final value?) 'reporter': value,
      if (instance.createdAt?.toIso8601String() case final value?)
        'created_at': value,
      if (instance.reportedAt?.toIso8601String() case final value?)
        'reported_at': value,
    };

const _$InspectionStatusEnumMap = {
  InspectionStatus.open: 'open',
  InspectionStatus.assigned: 'assigned',
  InspectionStatus.onSite: 'on_site',
  InspectionStatus.closedConfirmed: 'closed_confirmed',
  InspectionStatus.closedNotFound: 'closed_not_found',
  InspectionStatus.closedUnreachable: 'closed_unreachable',
  InspectionStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$InspectionOriginEnumMap = {
  InspectionOrigin.report: 'report',
  InspectionOrigin.spike: 'spike',
  InspectionOrigin.hotspot: 'hotspot',
  InspectionOrigin.plan: 'plan',
  InspectionOrigin.manual: 'manual',
  InspectionOrigin.unknownDefaultOpenApi: 'unknown_default_open_api',
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
