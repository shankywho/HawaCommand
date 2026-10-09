// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_timeline_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportTimelineEntry _$ReportTimelineEntryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportTimelineEntry',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status', 'at'],
        );
        final val = ReportTimelineEntry(
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$ReportStatusEnumMap, v,
                  unknownValue: ReportStatus.unknownDefaultOpenApi)),
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportTimelineEntryToJson(
        ReportTimelineEntry instance) =>
    <String, dynamic>{
      'status': _$ReportStatusEnumMap[instance.status]!,
      'at': instance.at.toIso8601String(),
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
