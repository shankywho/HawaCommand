// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_verify_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpVerifyIn _$OtpVerifyInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OtpVerifyIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['phone_e164', 'code'],
        );
        final val = OtpVerifyIn(
          phoneE164: $checkedConvert('phone_e164', (v) => v as String),
          code: $checkedConvert('code', (v) => v as String),
          requestId: $checkedConvert('request_id', (v) => v as String?),
          deviceLabel: $checkedConvert('device_label', (v) => v as String?),
          installId: $checkedConvert('install_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'phoneE164': 'phone_e164',
        'requestId': 'request_id',
        'deviceLabel': 'device_label',
        'installId': 'install_id'
      },
    );

Map<String, dynamic> _$OtpVerifyInToJson(OtpVerifyIn instance) =>
    <String, dynamic>{
      'phone_e164': instance.phoneE164,
      'code': instance.code,
      if (instance.requestId case final value?) 'request_id': value,
      if (instance.deviceLabel case final value?) 'device_label': value,
      if (instance.installId case final value?) 'install_id': value,
    };
