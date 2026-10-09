// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ward_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WardRef _$WardRefFromJson(Map<String, dynamic> json) => $checkedCreate(
      'WardRef',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ward_id'],
        );
        final val = WardRef(
          wardId: $checkedConvert('ward_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'wardId': 'ward_id'},
    );

Map<String, dynamic> _$WardRefToJson(WardRef instance) => <String, dynamic>{
      'ward_id': instance.wardId,
      if (instance.name case final value?) 'name': value,
    };
