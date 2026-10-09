// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_inspection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportInspection _$ReportInspectionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportInspection',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'status'],
        );
        final val = ReportInspection(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$InspectionStatusEnumMap, v,
                  unknownValue: InspectionStatus.unknownDefaultOpenApi)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ReportInspectionToJson(ReportInspection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$InspectionStatusEnumMap[instance.status]!,
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
