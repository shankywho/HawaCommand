// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_line_string.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoLineString _$GeoLineStringFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GeoLineString',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'coordinates'],
        );
        final val = GeoLineString(
          type: $checkedConvert('type', (v) => v as String),
          coordinates: $checkedConvert(
              'coordinates',
              (v) => (v as List<dynamic>)
                  .map((e) => (e as List<dynamic>)
                      .map((e) => (e as num).toDouble())
                      .toList())
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GeoLineStringToJson(GeoLineString instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };
