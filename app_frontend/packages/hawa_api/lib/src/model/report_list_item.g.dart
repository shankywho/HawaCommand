// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_list_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportListItem _$ReportListItemFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportListItem',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'status', 'created_at'],
        );
        final val = ReportListItem(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$ReportStatusEnumMap, v,
                  unknownValue: ReportStatus.unknownDefaultOpenApi)),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          clientReportId:
              $checkedConvert('client_report_id', (v) => v as String?),
          wardId: $checkedConvert('ward_id', (v) => v as String?),
          note: $checkedConvert('note', (v) => v as String?),
          thumbnailUrl: $checkedConvert('thumbnail_url', (v) => v as String?),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          verificationLabel: $checkedConvert(
              'verification_label',
              (v) => $enumDecodeNullable(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          inspectionStatus: $checkedConvert(
              'inspection_status',
              (v) => $enumDecodeNullable(_$InspectionStatusEnumMap, v,
                  unknownValue: InspectionStatus.unknownDefaultOpenApi)),
          outcomeText: $checkedConvert('outcome_text', (v) => v as String?),
          outcomeTextHi:
              $checkedConvert('outcome_text_hi', (v) => v as String?),
          closedAt: $checkedConvert('closed_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          source_: $checkedConvert(
              'source',
              (v) => $enumDecodeNullable(_$ReportSourceEnumMap, v,
                  unknownValue: ReportSource.unknownDefaultOpenApi)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'clientReportId': 'client_report_id',
        'wardId': 'ward_id',
        'thumbnailUrl': 'thumbnail_url',
        'placeName': 'place_name',
        'verificationLabel': 'verification_label',
        'inspectionStatus': 'inspection_status',
        'outcomeText': 'outcome_text',
        'outcomeTextHi': 'outcome_text_hi',
        'closedAt': 'closed_at',
        'source_': 'source',
        'isSimulated': 'is_simulated'
      },
    );

Map<String, dynamic> _$ReportListItemToJson(ReportListItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$ReportStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      if (instance.clientReportId case final value?) 'client_report_id': value,
      if (instance.wardId case final value?) 'ward_id': value,
      if (instance.note case final value?) 'note': value,
      if (instance.thumbnailUrl case final value?) 'thumbnail_url': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
      if (_$CauseLabelEnumMap[instance.verificationLabel] case final value?)
        'verification_label': value,
      if (_$InspectionStatusEnumMap[instance.inspectionStatus]
          case final value?)
        'inspection_status': value,
      if (instance.outcomeText case final value?) 'outcome_text': value,
      if (instance.outcomeTextHi case final value?) 'outcome_text_hi': value,
      if (instance.closedAt?.toIso8601String() case final value?)
        'closed_at': value,
      if (_$ReportSourceEnumMap[instance.source_] case final value?)
        'source': value,
      if (instance.isSimulated case final value?) 'is_simulated': value,
    };

const _$ReportStatusEnumMap = {
  ReportStatus.submitted: 'submitted',
  ReportStatus.verifying: 'verifying',
  ReportStatus.verified: 'verified',
  ReportStatus.rejected: 'rejected',
  ReportStatus.ticketed: 'ticketed',
  ReportStatus.closed: 'closed',
  ReportStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
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

const _$InspectionStatusEnumMap = {
  InspectionStatus.open: 'open',
  InspectionStatus.assigned: 'assigned',
  InspectionStatus.onSite: 'on_site',
  InspectionStatus.closedConfirmed: 'closed_confirmed',
  InspectionStatus.closedNotFound: 'closed_not_found',
  InspectionStatus.closedUnreachable: 'closed_unreachable',
  InspectionStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$ReportSourceEnumMap = {
  ReportSource.app: 'app',
  ReportSource.whatsapp: 'whatsapp',
  ReportSource.web: 'web',
  ReportSource.unknownDefaultOpenApi: 'unknown_default_open_api',
};
