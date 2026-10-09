// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignOut _$PresignOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PresignOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['key', 'url', 'method', 'expires_at'],
        );
        final val = PresignOut(
          key: $checkedConvert('key', (v) => v as String),
          url: $checkedConvert('url', (v) => v as String),
          method: $checkedConvert('method', (v) => v as String),
          expiresAt:
              $checkedConvert('expires_at', (v) => DateTime.parse(v as String)),
          fields: $checkedConvert(
              'fields',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as String),
                  )),
          headers: $checkedConvert(
              'headers',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as String),
                  )),
          maxBytes: $checkedConvert('max_bytes', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'expiresAt': 'expires_at', 'maxBytes': 'max_bytes'},
    );

Map<String, dynamic> _$PresignOutToJson(PresignOut instance) =>
    <String, dynamic>{
      'key': instance.key,
      'url': instance.url,
      'method': instance.method,
      'expires_at': instance.expiresAt.toIso8601String(),
      if (instance.fields case final value?) 'fields': value,
      if (instance.headers case final value?) 'headers': value,
      if (instance.maxBytes case final value?) 'max_bytes': value,
    };
