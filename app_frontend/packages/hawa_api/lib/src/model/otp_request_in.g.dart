// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'otp_request_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpRequestIn _$OtpRequestInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OtpRequestIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['phone_e164', 'channel', 'lang'],
        );
        final val = OtpRequestIn(
          phoneE164: $checkedConvert('phone_e164', (v) => v as String),
          channel: $checkedConvert(
              'channel',
              (v) => $enumDecode(_$OtpChannelEnumMap, v,
                  unknownValue: OtpChannel.unknownDefaultOpenApi)),
          lang: $checkedConvert(
              'lang',
              (v) => $enumDecode(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
          appSignature: $checkedConvert('app_signature', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'phoneE164': 'phone_e164',
        'appSignature': 'app_signature'
      },
    );

Map<String, dynamic> _$OtpRequestInToJson(OtpRequestIn instance) =>
    <String, dynamic>{
      'phone_e164': instance.phoneE164,
      'channel': _$OtpChannelEnumMap[instance.channel]!,
      'lang': _$LangEnumMap[instance.lang]!,
      if (instance.appSignature case final value?) 'app_signature': value,
    };

const _$OtpChannelEnumMap = {
  OtpChannel.sms: 'sms',
  OtpChannel.whatsapp: 'whatsapp',
  OtpChannel.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};
