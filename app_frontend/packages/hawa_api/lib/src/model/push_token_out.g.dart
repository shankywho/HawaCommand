// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushTokenOut _$PushTokenOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PushTokenOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'platform'],
        );
        final val = PushTokenOut(
          id: $checkedConvert('id', (v) => v as String),
          platform: $checkedConvert(
              'platform',
              (v) => $enumDecode(_$PushPlatformEnumMap, v,
                  unknownValue: PushPlatform.unknownDefaultOpenApi)),
          lastSeenAt: $checkedConvert('last_seen_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'lastSeenAt': 'last_seen_at'},
    );

Map<String, dynamic> _$PushTokenOutToJson(PushTokenOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'platform': _$PushPlatformEnumMap[instance.platform]!,
      if (instance.lastSeenAt?.toIso8601String() case final value?)
        'last_seen_at': value,
    };

const _$PushPlatformEnumMap = {
  PushPlatform.android: 'android',
  PushPlatform.ios: 'ios',
  PushPlatform.web: 'web',
  PushPlatform.unknownDefaultOpenApi: 'unknown_default_open_api',
};
