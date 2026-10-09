// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_patch_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MePatchIn _$MePatchInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'MePatchIn',
      json,
      ($checkedConvert) {
        final val = MePatchIn(
          lang: $checkedConvert(
              'lang',
              (v) => $enumDecodeNullable(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
          notificationPrefs: $checkedConvert(
              'notification_prefs',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as bool),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {'notificationPrefs': 'notification_prefs'},
    );

Map<String, dynamic> _$MePatchInToJson(MePatchIn instance) => <String, dynamic>{
      if (_$LangEnumMap[instance.lang] case final value?) 'lang': value,
      if (instance.notificationPrefs case final value?)
        'notification_prefs': value,
    };

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};
