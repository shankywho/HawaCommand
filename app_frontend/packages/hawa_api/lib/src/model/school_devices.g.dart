// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_devices.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolDevices _$SchoolDevicesFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SchoolDevices',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['outdoor', 'indoor'],
        );
        final val = SchoolDevices(
          outdoor: $checkedConvert('outdoor', (v) => v as String),
          indoor: $checkedConvert('indoor', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$SchoolDevicesToJson(SchoolDevices instance) =>
    <String, dynamic>{
      'outdoor': instance.outdoor,
      'indoor': instance.indoor,
    };
