// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_detail_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportDetailOut _$ReportDetailOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportDetailOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'status',
            'location',
            'created_at',
            'timeline',
            'is_simulated'
          ],
        );
        final val = ReportDetailOut(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$ReportStatusEnumMap, v,
                  unknownValue: ReportStatus.unknownDefaultOpenApi)),
          location: $checkedConvert(
              'location', (v) => GeoPoint.fromJson(v as Map<String, dynamic>)),
          createdAt:
              $checkedConvert('created_at', (v) => DateTime.parse(v as String)),
          timeline: $checkedConvert(
              'timeline',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      ReportTimelineEntry.fromJson(e as Map<String, dynamic>))
                  .toList()),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          clientReportId:
              $checkedConvert('client_report_id', (v) => v as String?),
          source_: $checkedConvert(
              'source',
              (v) => $enumDecodeNullable(_$ReportSourceEnumMap, v,
                  unknownValue: ReportSource.unknownDefaultOpenApi)),
          accuracyM:
              $checkedConvert('accuracy_m', (v) => (v as num?)?.toDouble()),
          wardId: $checkedConvert('ward_id', (v) => v as String?),
          cellId: $checkedConvert('cell_id', (v) => v as String?),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          note: $checkedConvert('note', (v) => v as String?),
          lang: $checkedConvert(
              'lang',
              (v) => $enumDecodeNullable(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
          category: $checkedConvert(
              'category',
              (v) => $enumDecodeNullable(_$ReportCategoryEnumMap, v,
                  unknownValue: ReportCategory.unknownDefaultOpenApi)),
          capturedAt: $checkedConvert('captured_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          photoUrl: $checkedConvert('photo_url', (v) => v as String?),
          verification: $checkedConvert(
              'verification',
              (v) => v == null
                  ? null
                  : ReportVerification.fromJson(v as Map<String, dynamic>)),
          inspection: $checkedConvert(
              'inspection',
              (v) => v == null
                  ? null
                  : ReportInspection.fromJson(v as Map<String, dynamic>)),
          outcome: $checkedConvert(
              'outcome',
              (v) => $enumDecodeNullable(_$InspectionOutcomeEnumMap, v,
                  unknownValue: InspectionOutcome.unknownDefaultOpenApi)),
          outcomeText: $checkedConvert('outcome_text', (v) => v as String?),
          outcomeTextHi:
              $checkedConvert('outcome_text_hi', (v) => v as String?),
          rejectionReason:
              $checkedConvert('rejection_reason', (v) => v as String?),
          rejectionReasonHi:
              $checkedConvert('rejection_reason_hi', (v) => v as String?),
          closedAt: $checkedConvert('closed_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'createdAt': 'created_at',
        'isSimulated': 'is_simulated',
        'clientReportId': 'client_report_id',
        'source_': 'source',
        'accuracyM': 'accuracy_m',
        'wardId': 'ward_id',
        'cellId': 'cell_id',
        'placeName': 'place_name',
        'capturedAt': 'captured_at',
        'photoUrl': 'photo_url',
        'outcomeText': 'outcome_text',
        'outcomeTextHi': 'outcome_text_hi',
        'rejectionReason': 'rejection_reason',
        'rejectionReasonHi': 'rejection_reason_hi',
        'closedAt': 'closed_at'
      },
    );

Map<String, dynamic> _$ReportDetailOutToJson(ReportDetailOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$ReportStatusEnumMap[instance.status]!,
      'location': instance.location.toJson(),
      'created_at': instance.createdAt.toIso8601String(),
      'timeline': instance.timeline.map((e) => e.toJson()).toList(),
      'is_simulated': instance.isSimulated,
      if (instance.clientReportId case final value?) 'client_report_id': value,
      if (_$ReportSourceEnumMap[instance.source_] case final value?)
        'source': value,
      if (instance.accuracyM case final value?) 'accuracy_m': value,
      if (instance.wardId case final value?) 'ward_id': value,
      if (instance.cellId case final value?) 'cell_id': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
      if (instance.note case final value?) 'note': value,
      if (_$LangEnumMap[instance.lang] case final value?) 'lang': value,
      if (_$ReportCategoryEnumMap[instance.category] case final value?)
        'category': value,
      if (instance.capturedAt?.toIso8601String() case final value?)
        'captured_at': value,
      if (instance.photoUrl case final value?) 'photo_url': value,
      if (instance.verification?.toJson() case final value?)
        'verification': value,
      if (instance.inspection?.toJson() case final value?) 'inspection': value,
      if (_$InspectionOutcomeEnumMap[instance.outcome] case final value?)
        'outcome': value,
      if (instance.outcomeText case final value?) 'outcome_text': value,
      if (instance.outcomeTextHi case final value?) 'outcome_text_hi': value,
      if (instance.rejectionReason case final value?) 'rejection_reason': value,
      if (instance.rejectionReasonHi case final value?)
        'rejection_reason_hi': value,
      if (instance.closedAt?.toIso8601String() case final value?)
        'closed_at': value,
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

const _$ReportSourceEnumMap = {
  ReportSource.app: 'app',
  ReportSource.whatsapp: 'whatsapp',
  ReportSource.web: 'web',
  ReportSource.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$ReportCategoryEnumMap = {
  ReportCategory.burning: 'burning',
  ReportCategory.dust: 'dust',
  ReportCategory.other: 'other',
  ReportCategory.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$InspectionOutcomeEnumMap = {
  InspectionOutcome.closedConfirmed: 'closed_confirmed',
  InspectionOutcome.closedNotFound: 'closed_not_found',
  InspectionOutcome.closedUnreachable: 'closed_unreachable',
  InspectionOutcome.unknownDefaultOpenApi: 'unknown_default_open_api',
};
