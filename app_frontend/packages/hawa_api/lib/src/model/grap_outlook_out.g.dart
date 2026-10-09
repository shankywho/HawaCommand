// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grap_outlook_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrapOutlookOut _$GrapOutlookOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GrapOutlookOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ward_id', 'issued_at', 'days', 'is_simulated'],
        );
        final val = GrapOutlookOut(
          wardId: $checkedConvert('ward_id', (v) => v as String),
          issuedAt:
              $checkedConvert('issued_at', (v) => DateTime.parse(v as String)),
          days: $checkedConvert(
              'days',
              (v) => (v as List<dynamic>)
                  .map((e) => GrapDay.fromJson(e as Map<String, dynamic>))
                  .toList()),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          modelVersion: $checkedConvert('model_version', (v) => v as String?),
          checklistStage:
              $checkedConvert('checklist_stage', (v) => (v as num?)?.toInt()),
          note: $checkedConvert('note', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'wardId': 'ward_id',
        'issuedAt': 'issued_at',
        'isSimulated': 'is_simulated',
        'modelVersion': 'model_version',
        'checklistStage': 'checklist_stage'
      },
    );

Map<String, dynamic> _$GrapOutlookOutToJson(GrapOutlookOut instance) =>
    <String, dynamic>{
      'ward_id': instance.wardId,
      'issued_at': instance.issuedAt.toIso8601String(),
      'days': instance.days.map((e) => e.toJson()).toList(),
      'is_simulated': instance.isSimulated,
      if (instance.modelVersion case final value?) 'model_version': value,
      if (instance.checklistStage case final value?) 'checklist_stage': value,
      if (instance.note case final value?) 'note': value,
    };
