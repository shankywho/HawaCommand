// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_score_component.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteScoreComponent _$SiteScoreComponentFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SiteScoreComponent',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['name', 'value'],
        );
        final val = SiteScoreComponent(
          name: $checkedConvert('name', (v) => v as String),
          value: $checkedConvert('value', (v) => (v as num).toDouble()),
          label: $checkedConvert(
              'label',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SiteScoreComponentToJson(SiteScoreComponent instance) =>
    <String, dynamic>{
      'name': instance.name,
      'value': instance.value,
      if (instance.label?.toJson() case final value?) 'label': value,
    };
