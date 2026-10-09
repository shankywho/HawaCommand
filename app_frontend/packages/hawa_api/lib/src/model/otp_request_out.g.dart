// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_request_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpRequestOut _$OtpRequestOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OtpRequestOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['status', 'expires_in', 'resend_after'],
        );
        final val = OtpRequestOut(
          status: $checkedConvert('status', (v) => v as String),
          expiresIn: $checkedConvert('expires_in', (v) => (v as num).toInt()),
          resendAfter:
              $checkedConvert('resend_after', (v) => (v as num).toInt()),
          requestId: $checkedConvert('request_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'expiresIn': 'expires_in',
        'resendAfter': 'resend_after',
        'requestId': 'request_id'
      },
    );

Map<String, dynamic> _$OtpRequestOutToJson(OtpRequestOut instance) =>
    <String, dynamic>{
      'status': instance.status,
      'expires_in': instance.expiresIn,
      'resend_after': instance.resendAfter,
      if (instance.requestId case final value?) 'request_id': value,
    };
