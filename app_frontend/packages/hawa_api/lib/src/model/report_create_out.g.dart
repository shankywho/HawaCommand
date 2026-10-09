// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_create_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportCreateOut _$ReportCreateOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportCreateOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['report_id', 'status'],
        );
        final val = ReportCreateOut(
          reportId: $checkedConvert('report_id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$ReportStatusEnumMap, v,
                  unknownValue: ReportStatus.unknownDefaultOpenApi)),
          clientReportId:
              $checkedConvert('client_report_id', (v) => v as String?),
          wardId: $checkedConvert('ward_id', (v) => v as String?),
          cellId: $checkedConvert('cell_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'reportId': 'report_id',
        'clientReportId': 'client_report_id',
        'wardId': 'ward_id',
        'cellId': 'cell_id'
      },
    );

Map<String, dynamic> _$ReportCreateOutToJson(ReportCreateOut instance) =>
    <String, dynamic>{
      'report_id': instance.reportId,
      'status': _$ReportStatusEnumMap[instance.status]!,
      if (instance.clientReportId case final value?) 'client_report_id': value,
      if (instance.wardId case final value?) 'ward_id': value,
      if (instance.cellId case final value?) 'cell_id': value,
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
