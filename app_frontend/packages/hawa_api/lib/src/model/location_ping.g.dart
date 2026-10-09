// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_ping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationPing _$LocationPingFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LocationPing',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['ts', 'lat', 'lon'],
        );
        final val = LocationPing(
          ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
          lat: $checkedConvert('lat', (v) => (v as num).toDouble()),
          lon: $checkedConvert('lon', (v) => (v as num).toDouble()),
          accuracyM:
              $checkedConvert('accuracy_m', (v) => (v as num?)?.toDouble()),
          speedKmh:
              $checkedConvert('speed_kmh', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {'accuracyM': 'accuracy_m', 'speedKmh': 'speed_kmh'},
    );

Map<String, dynamic> _$LocationPingToJson(LocationPing instance) =>
    <String, dynamic>{
      'ts': instance.ts.toIso8601String(),
      'lat': instance.lat,
      'lon': instance.lon,
      if (instance.accuracyM case final value?) 'accuracy_m': value,
      if (instance.speedKmh case final value?) 'speed_kmh': value,
    };
