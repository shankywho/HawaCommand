// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lat_lon.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LatLon _$LatLonFromJson(Map<String, dynamic> json) => $checkedCreate(
      'LatLon',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['lat', 'lon'],
        );
        final val = LatLon(
          lat: $checkedConvert('lat', (v) => (v as num).toDouble()),
          lon: $checkedConvert('lon', (v) => (v as num).toDouble()),
        );
        return val;
      },
    );

Map<String, dynamic> _$LatLonToJson(LatLon instance) => <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
    };
