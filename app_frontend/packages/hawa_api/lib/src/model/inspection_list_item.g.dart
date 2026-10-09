// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionListItem _$InspectionListItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InspectionListItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'status',
            'origin',
            'priority',
            'target',
            'created_at',
            'is_simulated'
          ],
        );
        final val = InspectionListItem(
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
          target: $checkedConvert(
              'target', (v) => GeoPoint.fromJson(v as Map<String, dynamic>)),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          wardId: $checkedConvert('ward_id', (v) => v as String?),
          cellId: $checkedConvert('cell_id', (v) => v as String?),
          reportId: $checkedConvert('report_id', (v) => v as String?),
          hotspotId: $checkedConvert('hotspot_id', (v) => v as String?),
          taskId: $checkedConvert('task_id', (v) => v as String?),
          siteId: $checkedConvert('site_id', (v) => v as String?),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          causeLabel: $checkedConvert(
              'cause_label',
              (v) => $enumDecodeNullable(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          causeConf:
              $checkedConvert('cause_conf', (v) => (v as num?)?.toDouble()),
          evidenceSummary: $checkedConvert(
              'evidence_summary',
              (v) => v == null
                  ? null
                  : EvidenceSummary.fromJson(v as Map<String, dynamic>)),
          assignedTeamAssetId:
              $checkedConvert('assigned_team_asset_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'isSimulated': 'is_simulated',
        'wardId': 'ward_id',
        'cellId': 'cell_id',
        'reportId': 'report_id',
        'hotspotId': 'hotspot_id',
        'taskId': 'task_id',
        'siteId': 'site_id',
        'placeName': 'place_name',
        'causeLabel': 'cause_label',
        'causeConf': 'cause_conf',
        'evidenceSummary': 'evidence_summary',
        'assignedTeamAssetId': 'assigned_team_asset_id'
      },
    );

Map<String, dynamic> _$InspectionListItemToJson(InspectionListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$InspectionStatusEnumMap[instance.status]!,
      'origin': _$InspectionOriginEnumMap[instance.origin]!,
      'priority': instance.priority,
      'target': instance.target.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'is_simulated': instance.isSimulated,
      if (instance.wardId case final value?) 'ward_id': value,
      if (instance.cellId case final value?) 'cell_id': value,
      if (instance.reportId case final value?) 'report_id': value,
      if (instance.hotspotId case final value?) 'hotspot_id': value,
      if (instance.taskId case final value?) 'task_id': value,
      if (instance.siteId case final value?) 'site_id': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
      if (_$CauseLabelEnumMap[instance.causeLabel] case final value?)
        'cause_label': value,
      if (instance.causeConf case final value?) 'cause_conf': value,
      if (instance.evidenceSummary?.toJson() case final value?)
        'evidence_summary': value,
      if (instance.assignedTeamAssetId case final value?)
        'assigned_team_asset_id': value,
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
