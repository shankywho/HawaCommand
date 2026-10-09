// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_close_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionCloseIn _$InspectionCloseInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InspectionCloseIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['outcome', 'evidence_keys', 'closed_at'],
        );
        final val = InspectionCloseIn(
          outcome: $checkedConvert(
              'outcome',
              (v) => $enumDecode(_$InspectionOutcomeEnumMap, v,
                  unknownValue: InspectionOutcome.unknownDefaultOpenApi)),
          evidenceKeys: $checkedConvert('evidence_keys',
              (v) => (v as List<dynamic>).map((e) => e as String).toList()),
          closedAt:
              $checkedConvert('closed_at', (v) => DateTime.parse(v as String)),
          notes: $checkedConvert('notes', (v) => v as String?),
          location: $checkedConvert(
              'location',
              (v) => v == null
                  ? null
                  : GeoPoint.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'evidenceKeys': 'evidence_keys',
        'closedAt': 'closed_at'
      },
    );

Map<String, dynamic> _$InspectionCloseInToJson(InspectionCloseIn instance) =>
    <String, dynamic>{
      'outcome': _$InspectionOutcomeEnumMap[instance.outcome]!,
      'evidence_keys': instance.evidenceKeys,
      'closed_at': instance.closedAt.toIso8601String(),
      if (instance.notes case final value?) 'notes': value,
      if (instance.location?.toJson() case final value?) 'location': value,
    };

const _$InspectionOutcomeEnumMap = {
  InspectionOutcome.closedConfirmed: 'closed_confirmed',
  InspectionOutcome.closedNotFound: 'closed_not_found',
  InspectionOutcome.closedUnreachable: 'closed_unreachable',
  InspectionOutcome.unknownDefaultOpenApi: 'unknown_default_open_api',
};
