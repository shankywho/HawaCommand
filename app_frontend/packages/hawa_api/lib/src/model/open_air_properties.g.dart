// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_air_properties.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenAirProperties _$OpenAirPropertiesFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OpenAirProperties',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'cell_id',
            'confidence',
            'aqi',
            'aqi_category',
            'is_simulated'
          ],
        );
        final val = OpenAirProperties(
          cellId: $checkedConvert('cell_id', (v) => v as String),
          confidence:
              $checkedConvert('confidence', (v) => (v as num).toDouble()),
          aqi: $checkedConvert('aqi', (v) => (v as num).toInt()),
          aqiCategory: $checkedConvert(
              'aqi_category',
              (v) => $enumDecode(_$AqiCategoryEnumMap, v,
                  unknownValue: AqiCategory.unknownDefaultOpenApi)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          pm25: $checkedConvert('pm25', (v) => (v as num?)?.toDouble()),
          pm10: $checkedConvert('pm10', (v) => (v as num?)?.toDouble()),
          no2Ppb: $checkedConvert('no2_ppb', (v) => (v as num?)?.toDouble()),
          dominantPollutant: $checkedConvert(
              'dominant_pollutant',
              (v) => $enumDecodeNullable(_$PollutantEnumMap, v,
                  unknownValue: Pollutant.unknownDefaultOpenApi)),
          causeLabel: $checkedConvert(
              'cause_label',
              (v) => $enumDecodeNullable(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          causeConf:
              $checkedConvert('cause_conf', (v) => (v as num?)?.toDouble()),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'cellId': 'cell_id',
        'aqiCategory': 'aqi_category',
        'isSimulated': 'is_simulated',
        'no2Ppb': 'no2_ppb',
        'dominantPollutant': 'dominant_pollutant',
        'causeLabel': 'cause_label',
        'causeConf': 'cause_conf',
        'placeName': 'place_name'
      },
    );

Map<String, dynamic> _$OpenAirPropertiesToJson(OpenAirProperties instance) =>
    <String, dynamic>{
      'cell_id': instance.cellId,
      'confidence': instance.confidence,
      'aqi': instance.aqi,
      'aqi_category': _$AqiCategoryEnumMap[instance.aqiCategory]!,
      'is_simulated': instance.isSimulated,
      if (instance.pm25 case final value?) 'pm25': value,
      if (instance.pm10 case final value?) 'pm10': value,
      if (instance.no2Ppb case final value?) 'no2_ppb': value,
      if (_$PollutantEnumMap[instance.dominantPollutant] case final value?)
        'dominant_pollutant': value,
      if (_$CauseLabelEnumMap[instance.causeLabel] case final value?)
        'cause_label': value,
      if (instance.causeConf case final value?) 'cause_conf': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
    };

const _$AqiCategoryEnumMap = {
  AqiCategory.good: 'good',
  AqiCategory.satisfactory: 'satisfactory',
  AqiCategory.moderate: 'moderate',
  AqiCategory.poor: 'poor',
  AqiCategory.veryPoor: 'very_poor',
  AqiCategory.severe: 'severe',
  AqiCategory.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$PollutantEnumMap = {
  Pollutant.pm1: 'pm1',
  Pollutant.pm25: 'pm25',
  Pollutant.pm10: 'pm10',
  Pollutant.no2: 'no2',
  Pollutant.co: 'co',
  Pollutant.nh3: 'nh3',
  Pollutant.voc: 'voc',
  Pollutant.co2: 'co2',
  Pollutant.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$CauseLabelEnumMap = {
  CauseLabel.dust: 'dust',
  CauseLabel.traffic: 'traffic',
  CauseLabel.burning: 'burning',
  CauseLabel.regionalSmoke: 'regional_smoke',
  CauseLabel.mixed: 'mixed',
  CauseLabel.unknown: 'unknown',
  CauseLabel.unknownDefaultOpenApi: 'unknown_default_open_api',
};
