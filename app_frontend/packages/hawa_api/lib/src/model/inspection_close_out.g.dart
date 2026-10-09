// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_close_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionCloseOut _$InspectionCloseOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InspectionCloseOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'status'],
        );
        final val = InspectionCloseOut(
          id: $checkedConvert('id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$InspectionStatusEnumMap, v,
                  unknownValue: InspectionStatus.unknownDefaultOpenApi)),
          closedAt: $checkedConvert('closed_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          applied: $checkedConvert('applied', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {'closedAt': 'closed_at'},
    );

Map<String, dynamic> _$InspectionCloseOutToJson(InspectionCloseOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$InspectionStatusEnumMap[instance.status]!,
      if (instance.closedAt?.toIso8601String() case final value?)
        'closed_at': value,
      if (instance.applied case final value?) 'applied': value,
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
