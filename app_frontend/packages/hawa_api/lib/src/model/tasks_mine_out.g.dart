// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tasks_mine_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TasksMineOut _$TasksMineOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'TasksMineOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['date', 'items'],
        );
        final val = TasksMineOut(
          date: $checkedConvert('date', (v) => DateTime.parse(v as String)),
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
          role: $checkedConvert(
              'role',
              (v) => $enumDecodeNullable(_$UserRoleEnumMap, v,
                  unknownValue: UserRole.unknownDefaultOpenApi)),
          asset: $checkedConvert(
              'asset',
              (v) => v == null
                  ? null
                  : TaskAsset.fromJson(v as Map<String, dynamic>)),
          shift: $checkedConvert(
              'shift',
              (v) => v == null
                  ? null
                  : TaskShift.fromJson(v as Map<String, dynamic>)),
          route: $checkedConvert(
              'route',
              (v) => v == null
                  ? null
                  : TaskRoute.fromJson(v as Map<String, dynamic>)),
          serverTime: $checkedConvert('server_time',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'serverTime': 'server_time'},
    );

Map<String, dynamic> _$TasksMineOutToJson(TasksMineOut instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'items': instance.items.map((e) => e.toJson()).toList(),
      if (_$UserRoleEnumMap[instance.role] case final value?) 'role': value,
      if (instance.asset?.toJson() case final value?) 'asset': value,
      if (instance.shift?.toJson() case final value?) 'shift': value,
      if (instance.route?.toJson() case final value?) 'route': value,
      if (instance.serverTime?.toIso8601String() case final value?)
        'server_time': value,
    };

const _$UserRoleEnumMap = {
  UserRole.admin: 'admin',
  UserRole.officer: 'officer',
  UserRole.analyst: 'analyst',
  UserRole.inspector: 'inspector',
  UserRole.driver: 'driver',
  UserRole.school: 'school',
  UserRole.siteManager: 'site_manager',
  UserRole.citizen: 'citizen',
  UserRole.unknownDefaultOpenApi: 'unknown_default_open_api',
};
