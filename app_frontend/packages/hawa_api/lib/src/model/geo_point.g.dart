// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'geo_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeoPoint _$GeoPointFromJson(Map<String, dynamic> json) => $checkedCreate(
      'GeoPoint',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['type', 'coordinates'],
        );
        final val = GeoPoint(
          type: $checkedConvert('type', (v) => v as String),
          coordinates: $checkedConvert(
              'coordinates',
              (v) => (v as List<dynamic>)
                  .map((e) => (e as num).toDouble())
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$GeoPointToJson(GeoPoint instance) => <String, dynamic>{
      'type': instance.type,
      'coordinates': instance.coordinates,
    };
