// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteRef _$SiteRefFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SiteRef',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['site_id', 'name'],
        );
        final val = SiteRef(
          siteId: $checkedConvert('site_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'siteId': 'site_id'},
    );

Map<String, dynamic> _$SiteRefToJson(SiteRef instance) => <String, dynamic>{
      'site_id': instance.siteId,
      'name': instance.name,
    };
