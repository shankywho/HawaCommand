// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_polygon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoPolygon _$GeoPolygonFromJson(Map<String, dynamic> json) => $checkedCreate(
      'GeoPolygon',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'coordinates'],
        );
        final val = GeoPolygon(
          type: $checkedConvert('type', (v) => v as String),
          coordinates: $checkedConvert(
              'coordinates',
              (v) => (v as List<dynamic>)
                  .map((e) => (e as List<dynamic>)
                      .map((e) => (e as List<dynamic>)
                          .map((e) => (e as num).toDouble())
                          .toList())
                      .toList())
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GeoPolygonToJson(GeoPolygon instance) =>
    <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };
