// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceState _$DeviceStateFromJson(Map<String, dynamic> json) => $checkedCreate(
      'DeviceState',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['device_id', 'status'],
        );
        final val = DeviceState(
          deviceId: $checkedConvert('device_id', (v) => v as String),
          status: $checkedConvert(
              'status',
              (v) => $enumDecode(_$DeviceStatusEnumMap, v,
                  unknownValue: DeviceStatus.unknownDefaultOpenApi)),
          lastSeenAt: $checkedConvert('last_seen_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceId': 'device_id',
        'lastSeenAt': 'last_seen_at'
      },
    );

Map<String, dynamic> _$DeviceStateToJson(DeviceState instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'status': _$DeviceStatusEnumMap[instance.status]!,
      if (instance.lastSeenAt?.toIso8601String() case final value?)
        'last_seen_at': value,
    };

const _$DeviceStatusEnumMap = {
  DeviceStatus.provisioned: 'provisioned',
  DeviceStatus.active: 'active',
  DeviceStatus.degraded: 'degraded',
  DeviceStatus.offline: 'offline',
  DeviceStatus.retired: 'retired',
  DeviceStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};
