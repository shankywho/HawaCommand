// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TokenResponse',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'access_token',
            'token_type',
            'expires_in',
            'refresh_token',
            'user'
          ],
        );
        final val = TokenResponse(
          accessToken: $checkedConvert('access_token', (v) => v as String),
          tokenType: $checkedConvert('token_type', (v) => v as String),
          expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
          refreshToken: $checkedConvert('refresh_token', (v) => v as String),
          user: $checkedConvert(
              'user', (v) => AuthUser.fromJson(v as Map<String, dynamic>)),
          refreshExpiresIn: $checkedConvert(
              'refresh_expires_in', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'accessToken': 'access_token',
        'tokenType': 'token_type',
        'expiresIn': 'expires_in',
        'refreshToken': 'refresh_token',
        'refreshExpiresIn': 'refresh_expires_in'
      },
    );

Map<String, dynamic> _$TokenResponseToJson(TokenResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
      'refresh_token': instance.refreshToken,
      'user': instance.user.toJson(),
      if (instance.refreshExpiresIn case final value?)
        'refresh_expires_in': value,
    };
