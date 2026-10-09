// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'me_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MeOut _$MeOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'MeOut',
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
        final val = MeOut(
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
          email: $checkedConvert('email', (v) => v as String?),
          phoneE164: $checkedConvert('phone_e164', (v) => v as String?),
          wards: $checkedConvert(
              'wards',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => WardRef.fromJson(e as Map<String, dynamic>))
                  .toList()),
          assetIds: $checkedConvert('asset_ids',
              (v) => (v as List<dynamic>?)?.map((e) => e as String).toList()),
          school: $checkedConvert(
              'school',
              (v) => v == null
                  ? null
                  : SchoolRef.fromJson(v as Map<String, dynamic>)),
          site: $checkedConvert(
              'site',
              (v) => v == null
                  ? null
                  : SiteRef.fromJson(v as Map<String, dynamic>)),
          currentShift: $checkedConvert('current_shift', (v) => v as String?),
          features: $checkedConvert(
              'features',
              (v) => v == null
                  ? null
                  : MeFeatures.fromJson(v as Map<String, dynamic>)),
          notificationPrefs: $checkedConvert(
              'notification_prefs',
              (v) => (v as Map<String, dynamic>?)?.map(
                    (k, e) => MapEntry(k, e as bool),
                  )),
        );
        return val;
      },
      fieldKeyMap: const {
        'displayName': 'display_name',
        'isSimulated': 'is_simulated',
        'phoneE164': 'phone_e164',
        'assetIds': 'asset_ids',
        'currentShift': 'current_shift',
        'notificationPrefs': 'notification_prefs'
      },
    );

Map<String, dynamic> _$MeOutToJson(MeOut instance) => <String, dynamic>{
      'id': instance.id,
      'role': _$UserRoleEnumMap[instance.role]!,
      'display_name': instance.displayName,
      'lang': _$LangEnumMap[instance.lang]!,
      'is_simulated': instance.isSimulated,
      if (instance.roles?.map((e) => _$UserRoleEnumMap[e]!).toList()
          case final value?)
        'roles': value,
      if (instance.email case final value?) 'email': value,
      if (instance.phoneE164 case final value?) 'phone_e164': value,
      if (instance.wards?.map((e) => e.toJson()).toList() case final value?)
        'wards': value,
      if (instance.assetIds case final value?) 'asset_ids': value,
      if (instance.school?.toJson() case final value?) 'school': value,
      if (instance.site?.toJson() case final value?) 'site': value,
      if (instance.currentShift case final value?) 'current_shift': value,
      if (instance.features?.toJson() case final value?) 'features': value,
      if (instance.notificationPrefs case final value?)
        'notification_prefs': value,
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
