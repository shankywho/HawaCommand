// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_asset.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskAsset _$TaskAssetFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TaskAsset',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'type', 'label', 'is_simulated'],
        );
        final val = TaskAsset(
          id: $checkedConvert('id', (v) => v as String),
          type: $checkedConvert(
              'type',
              (v) => $enumDecode(_$AssetTypeEnumMap, v,
                  unknownValue: AssetType.unknownDefaultOpenApi)),
          label: $checkedConvert('label', (v) => v as String),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          tagDeviceId: $checkedConvert('tag_device_id', (v) => v as String?),
          tagStatus: $checkedConvert(
              'tag_status',
              (v) => $enumDecodeNullable(_$DeviceStatusEnumMap, v,
                  unknownValue: DeviceStatus.unknownDefaultOpenApi)),
          tagLastSeenAt: $checkedConvert('tag_last_seen_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          capacityLitres: $checkedConvert(
              'capacity_litres', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'isSimulated': 'is_simulated',
        'tagDeviceId': 'tag_device_id',
        'tagStatus': 'tag_status',
        'tagLastSeenAt': 'tag_last_seen_at',
        'capacityLitres': 'capacity_litres'
      },
    );

Map<String, dynamic> _$TaskAssetToJson(TaskAsset instance) => <String, dynamic>{
      'id': instance.id,
      'type': _$AssetTypeEnumMap[instance.type]!,
      'label': instance.label,
      'is_simulated': instance.isSimulated,
      if (instance.tagDeviceId case final value?) 'tag_device_id': value,
      if (_$DeviceStatusEnumMap[instance.tagStatus] case final value?)
        'tag_status': value,
      if (instance.tagLastSeenAt?.toIso8601String() case final value?)
        'tag_last_seen_at': value,
      if (instance.capacityLitres case final value?) 'capacity_litres': value,
    };

const _$AssetTypeEnumMap = {
  AssetType.sprinkler: 'sprinkler',
  AssetType.antiSmogGun: 'anti_smog_gun',
  AssetType.sweeper: 'sweeper',
  AssetType.inspectionTeam: 'inspection_team',
  AssetType.unknownDefaultOpenApi: 'unknown_default_open_api',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.provisioned: 'provisioned',
  DeviceStatus.active: 'active',
  DeviceStatus.degraded: 'degraded',
  DeviceStatus.offline: 'offline',
  DeviceStatus.retired: 'retired',
  DeviceStatus.unknownDefaultOpenApi: 'unknown_default_open_api',
};
