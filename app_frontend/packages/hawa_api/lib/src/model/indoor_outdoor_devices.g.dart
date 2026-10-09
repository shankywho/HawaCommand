// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indoor_outdoor_devices.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndoorOutdoorDevices _$IndoorOutdoorDevicesFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'IndoorOutdoorDevices',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['outdoor', 'indoor'],
        );
        final val = IndoorOutdoorDevices(
          outdoor: $checkedConvert('outdoor',
              (v) => DeviceState.fromJson(v as Map<String, dynamic>)),
          indoor: $checkedConvert(
              'indoor', (v) => DeviceState.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$IndoorOutdoorDevicesToJson(
        IndoorOutdoorDevices instance) =>
    <String, dynamic>{
      'outdoor': instance.outdoor.toJson(),
      'indoor': instance.indoor.toJson(),
    };
