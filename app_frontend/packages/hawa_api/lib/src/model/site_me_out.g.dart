// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_me_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteMeOut _$SiteMeOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SiteMeOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'site_id',
            'type',
            'name',
            'grade',
            'is_simulated'
          ],
        );
        final val = SiteMeOut(
          siteId: $checkedConvert('site_id', (v) => v as String),
          type: $checkedConvert(
              'type',
              (v) => $enumDecode(_$SiteTypeEnumMap, v,
                  unknownValue: SiteType.unknownDefaultOpenApi)),
          name: $checkedConvert('name', (v) => v as String),
          grade: $checkedConvert(
              'grade',
              (v) => $enumDecode(_$SiteGradeEnumMap, v,
                  unknownValue: SiteGrade.unknownDefaultOpenApi)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          wardId: $checkedConvert('ward_id', (v) => v as String?),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          gradeSince: $checkedConvert('grade_since',
              (v) => v == null ? null : DateTime.parse(v as String)),
          score: $checkedConvert('score', (v) => (v as num?)?.toDouble()),
          violations:
              $checkedConvert('violations', (v) => (v as num?)?.toInt()),
          flags30d: $checkedConvert('flags_30d', (v) => (v as num?)?.toInt()),
          lastInspectionAt: $checkedConvert('last_inspection_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          pm10Trend: $checkedConvert(
              'pm10_trend',
              (v) => (v as List<dynamic>?)
                  ?.map(
                      (e) => Pm10TrendPoint.fromJson(e as Map<String, dynamic>))
                  .toList()),
          components: $checkedConvert(
              'components',
              (v) => (v as List<dynamic>?)
                  ?.map((e) =>
                      SiteScoreComponent.fromJson(e as Map<String, dynamic>))
                  .toList()),
          tips: $checkedConvert(
              'tips',
              (v) => (v as List<dynamic>?)
                  ?.map(
                      (e) => LocalizedText.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteId': 'site_id',
        'isSimulated': 'is_simulated',
        'wardId': 'ward_id',
        'placeName': 'place_name',
        'gradeSince': 'grade_since',
        'flags30d': 'flags_30d',
        'lastInspectionAt': 'last_inspection_at',
        'pm10Trend': 'pm10_trend'
      },
    );

Map<String, dynamic> _$SiteMeOutToJson(SiteMeOut instance) => <String, dynamic>{
      'site_id': instance.siteId,
      'type': _$SiteTypeEnumMap[instance.type]!,
      'name': instance.name,
      'grade': _$SiteGradeEnumMap[instance.grade]!,
      'is_simulated': instance.isSimulated,
      if (instance.wardId case final value?) 'ward_id': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
      if (instance.gradeSince?.toIso8601String() case final value?)
        'grade_since': value,
      if (instance.score case final value?) 'score': value,
      if (instance.violations case final value?) 'violations': value,
      if (instance.flags30d case final value?) 'flags_30d': value,
      if (instance.lastInspectionAt?.toIso8601String() case final value?)
        'last_inspection_at': value,
      if (instance.pm10Trend?.map((e) => e.toJson()).toList() case final value?)
        'pm10_trend': value,
      if (instance.components?.map((e) => e.toJson()).toList()
          case final value?)
        'components': value,
      if (instance.tips?.map((e) => e.toJson()).toList() case final value?)
        'tips': value,
    };

const _$SiteTypeEnumMap = {
  SiteType.construction: 'construction',
  SiteType.industrialUnit: 'industrial_unit',
  SiteType.wasteSite: 'waste_site',
  SiteType.other: 'other',
  SiteType.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$SiteGradeEnumMap = {
  SiteGrade.A: 'A',
  SiteGrade.B: 'B',
  SiteGrade.C: 'C',
  SiteGrade.unknownDefaultOpenApi: 'unknown_default_open_api',
};
