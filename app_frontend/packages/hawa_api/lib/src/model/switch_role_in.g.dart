// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'switch_role_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SwitchRoleIn _$SwitchRoleInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SwitchRoleIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['role'],
        );
        final val = SwitchRoleIn(
          role: $checkedConvert(
              'role',
              (v) => $enumDecode(_$UserRoleEnumMap, v,
                  unknownValue: UserRole.unknownDefaultOpenApi)),
        );
        return val;
      },
    );

Map<String, dynamic> _$SwitchRoleInToJson(SwitchRoleIn instance) =>
    <String, dynamic>{
      'role': _$UserRoleEnumMap[instance.role]!,
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
