// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_air_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenAirOut _$OpenAirOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OpenAirOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'as_of', 'features'],
        );
        final val = OpenAirOut(
          type: $checkedConvert('type', (v) => v as String),
          asOf: $checkedConvert('as_of', (v) => DateTime.parse(v as String)),
          features: $checkedConvert(
              'features',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => OpenAirFeature.fromJson(e as Map<String, dynamic>))
                  .toList()),
          resolutionM:
              $checkedConvert('resolution_m', (v) => (v as num?)?.toInt()),
          aqiBasis: $checkedConvert('aqi_basis', (v) => v as String?),
          licence: $checkedConvert(
              'licence',
              (v) => v == null
                  ? null
                  : Licence.fromJson(v as Map<String, dynamic>)),
          methodsUrl: $checkedConvert('methods_url', (v) => v as String?),
          advice: $checkedConvert(
              'advice',
              (v) => v == null
                  ? null
                  : CitizenAdvice.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'asOf': 'as_of',
        'resolutionM': 'resolution_m',
        'aqiBasis': 'aqi_basis',
        'methodsUrl': 'methods_url'
      },
    );

Map<String, dynamic> _$OpenAirOutToJson(OpenAirOut instance) =>
    <String, dynamic>{
      'type': instance.type,
      'as_of': instance.asOf.toIso8601String(),
      'features': instance.features.map((e) => e.toJson()).toList(),
      if (instance.resolutionM case final value?) 'resolution_m': value,
      if (instance.aqiBasis case final value?) 'aqi_basis': value,
      if (instance.licence?.toJson() case final value?) 'licence': value,
      if (instance.methodsUrl case final value?) 'methods_url': value,
      if (instance.advice?.toJson() case final value?) 'advice': value,
    };
