// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushTokenIn _$PushTokenInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PushTokenIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['token', 'platform'],
        );
        final val = PushTokenIn(
          token: $checkedConvert('token', (v) => v as String),
          platform: $checkedConvert(
              'platform',
              (v) => $enumDecode(_$PushPlatformEnumMap, v,
                  unknownValue: PushPlatform.unknownDefaultOpenApi)),
          appFlavor: $checkedConvert('app_flavor', (v) => v as String?),
          appVersion: $checkedConvert('app_version', (v) => v as String?),
          locale: $checkedConvert('locale', (v) => v as String?),
          deviceLabel: $checkedConvert('device_label', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'appFlavor': 'app_flavor',
        'appVersion': 'app_version',
        'deviceLabel': 'device_label'
      },
    );

Map<String, dynamic> _$PushTokenInToJson(PushTokenIn instance) =>
    <String, dynamic>{
      'token': instance.token,
      'platform': _$PushPlatformEnumMap[instance.platform]!,
      if (instance.appFlavor case final value?) 'app_flavor': value,
      if (instance.appVersion case final value?) 'app_version': value,
      if (instance.locale case final value?) 'locale': value,
      if (instance.deviceLabel case final value?) 'device_label': value,
    };

const _$PushPlatformEnumMap = {
  PushPlatform.android: 'android',
  PushPlatform.ios: 'ios',
  PushPlatform.web: 'web',
  PushPlatform.unknownDefaultOpenApi: 'unknown_default_open_api',
};
