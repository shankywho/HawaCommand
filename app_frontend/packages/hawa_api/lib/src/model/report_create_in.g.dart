// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_create_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportCreateIn _$ReportCreateInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportCreateIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'client_report_id',
            'photo_key',
            'location',
            'captured_at'
          ],
        );
        final val = ReportCreateIn(
          clientReportId:
              $checkedConvert('client_report_id', (v) => v as String),
          photoKey: $checkedConvert('photo_key', (v) => v as String),
          location: $checkedConvert(
              'location', (v) => GeoPoint.fromJson(v as Map<String, dynamic>)),
          capturedAt: $checkedConvert(
              'captured_at', (v) => DateTime.parse(v as String)),
          accuracyM:
              $checkedConvert('accuracy_m', (v) => (v as num?)?.toDouble()),
          note: $checkedConvert('note', (v) => v as String?),
          lang: $checkedConvert(
              'lang',
              (v) => $enumDecodeNullable(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
          category: $checkedConvert(
              'category',
              (v) => $enumDecodeNullable(_$ReportCategoryEnumMap, v,
                  unknownValue: ReportCategory.unknownDefaultOpenApi)),
        );
        return val;
      },
      fieldKeyMap: const {
        'clientReportId': 'client_report_id',
        'photoKey': 'photo_key',
        'capturedAt': 'captured_at',
        'accuracyM': 'accuracy_m'
      },
    );

Map<String, dynamic> _$ReportCreateInToJson(ReportCreateIn instance) =>
    <String, dynamic>{
      'client_report_id': instance.clientReportId,
      'photo_key': instance.photoKey,
      'location': instance.location.toJson(),
      'captured_at': instance.capturedAt.toIso8601String(),
      if (instance.accuracyM case final value?) 'accuracy_m': value,
      if (instance.note case final value?) 'note': value,
      if (_$LangEnumMap[instance.lang] case final value?) 'lang': value,
      if (_$ReportCategoryEnumMap[instance.category] case final value?)
        'category': value,
    };

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$ReportCategoryEnumMap = {
  ReportCategory.burning: 'burning',
  ReportCategory.dust: 'dust',
  ReportCategory.other: 'other',
  ReportCategory.unknownDefaultOpenApi: 'unknown_default_open_api',
};
