// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AuthUser',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'role',
            'display_name',
            'lang',
            'is_simulated'
          ],
        );
        final val = AuthUser(
          id: $checkedConvert('id', (v) => v as String),
          role: $checkedConvert(
              'role',
              (v) => $enumDecode(_$UserRoleEnumMap, v,
                  unknownValue: UserRole.unknownDefaultOpenApi)),
          displayName: $checkedConvert('display_name', (v) => v as String),
          lang: $checkedConvert(
              'lang',
              (v) => $enumDecode(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          roles: $checkedConvert(
              'roles',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => $enumDecode(_$UserRoleEnumMap, e))
                  .toList()),
          wards: $checkedConvert('wards',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          assetIds: $checkedConvert('asset_ids',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          schoolId: $checkedConvert('school_id', (v) => v as String?),
          siteId: $checkedConvert('site_id', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'displayName': 'display_name',
        'isSimulated': 'is_simulated',
        'assetIds': 'asset_ids',
        'schoolId': 'school_id',
        'siteId': 'site_id'
      },
    );

Map<String, dynamic> _$AuthUserToJson(AuthUser instance) => <String, dynamic>{
      'id': instance.id,
      'role': _$UserRoleEnumMap[instance.role]!,
      'display_name': instance.displayName,
      'lang': _$LangEnumMap[instance.lang]!,
      'is_simulated': instance.isSimulated,
      if (instance.roles?.map((e) => _$UserRoleEnumMap[e]!).toList()
          case final value?)
        'roles': value,
      if (instance.wards case final value?) 'wards': value,
      if (instance.assetIds case final value?) 'asset_ids': value,
      if (instance.schoolId case final value?) 'school_id': value,
      if (instance.siteId case final value?) 'site_id': value,
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

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};
