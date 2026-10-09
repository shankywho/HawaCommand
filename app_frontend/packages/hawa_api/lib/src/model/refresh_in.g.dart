// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RefreshIn _$RefreshInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'RefreshIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['refresh_token'],
        );
        final val = RefreshIn(
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'refreshToken': 'refresh_token'},
    );

Map<String, dynamic> _$RefreshInToJson(RefreshIn instance) => <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };
