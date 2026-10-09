// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_air_feature.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenAirFeature _$OpenAirFeatureFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OpenAirFeature',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'id', 'geometry', 'properties'],
        );
        final val = OpenAirFeature(
          type: $checkedConvert('type', (v) => v as String),
          id: $checkedConvert('id', (v) => v as String),
          geometry: $checkedConvert('geometry',
              (v) => GeoPolygon.fromJson(v as Map<String, dynamic>)),
          properties: $checkedConvert('properties',
              (v) => OpenAirProperties.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$OpenAirFeatureToJson(OpenAirFeature instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'geometry': instance.geometry.toJson(),
      'properties': instance.properties.toJson(),
    };
