// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'localized_text.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LocalizedText',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['en'],
        );
        final val = LocalizedText(
          en: $checkedConvert('en', (v) => v as String),
          hi: $checkedConvert('hi', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{
      'en': instance.en,
      if (instance.hi case final value?) 'hi': value,
    };
