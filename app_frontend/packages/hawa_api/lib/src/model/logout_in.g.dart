// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'logout_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogoutIn _$LogoutInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'LogoutIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['refresh_token'],
        );
        final val = LogoutIn(
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          allDevices: $checkedConvert('all_devices', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'refreshToken': 'refresh_token',
        'allDevices': 'all_devices'
      },
    );

Map<String, dynamic> _$LogoutInToJson(LogoutIn instance) => <String, dynamic>{
      'refresh_token': instance.refreshToken,
      if (instance.allDevices case final value?) 'all_devices': value,
    };
