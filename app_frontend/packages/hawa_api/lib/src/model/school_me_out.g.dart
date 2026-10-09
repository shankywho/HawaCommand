// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_me_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolMeOut _$SchoolMeOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SchoolMeOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'school_id',
            'name',
            'ward_id',
            'cell_id',
            'location',
            'is_simulated'
          ],
        );
        final val = SchoolMeOut(
          schoolId: $checkedConvert('school_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          wardId: $checkedConvert('ward_id', (v) => v as String),
          cellId: $checkedConvert('cell_id', (v) => v as String),
          location: $checkedConvert(
              'location', (v) => GeoPoint.fromJson(v as Map<String, dynamic>)),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          nameHi: $checkedConvert('name_hi', (v) => v as String?),
          forecastCellId:
              $checkedConvert('forecast_cell_id', (v) => v as String?),
          devices: $checkedConvert(
              'devices',
              (v) => v == null
                  ? null
                  : SchoolDevices.fromJson(v as Map<String, dynamic>)),
          hours: $checkedConvert(
              'hours',
              (v) => v == null
                  ? null
                  : SchoolHours.fromJson(v as Map<String, dynamic>)),
          now: $checkedConvert(
              'now',
              (v) => v == null
                  ? null
                  : SchoolNow.fromJson(v as Map<String, dynamic>)),
          today: $checkedConvert(
              'today',
              (v) => v == null
                  ? null
                  : SchoolToday.fromJson(v as Map<String, dynamic>)),
          whatsappOptIn: $checkedConvert('whatsapp_opt_in', (v) => v as bool?),
          preferredLang: $checkedConvert(
              'preferred_lang',
              (v) => $enumDecodeNullable(_$LangEnumMap, v,
                  unknownValue: Lang.unknownDefaultOpenApi)),
        );
        return val;
      },
      fieldKeyMap: const {
        'schoolId': 'school_id',
        'wardId': 'ward_id',
        'cellId': 'cell_id',
        'isSimulated': 'is_simulated',
        'nameHi': 'name_hi',
        'forecastCellId': 'forecast_cell_id',
        'whatsappOptIn': 'whatsapp_opt_in',
        'preferredLang': 'preferred_lang'
      },
    );

Map<String, dynamic> _$SchoolMeOutToJson(SchoolMeOut instance) =>
    <String, dynamic>{
      'school_id': instance.schoolId,
      'name': instance.name,
      'ward_id': instance.wardId,
      'cell_id': instance.cellId,
      'location': instance.location.toJson(),
      'is_simulated': instance.isSimulated,
      if (instance.nameHi case final value?) 'name_hi': value,
      if (instance.forecastCellId case final value?) 'forecast_cell_id': value,
      if (instance.devices?.toJson() case final value?) 'devices': value,
      if (instance.hours?.toJson() case final value?) 'hours': value,
      if (instance.now?.toJson() case final value?) 'now': value,
      if (instance.today?.toJson() case final value?) 'today': value,
      if (instance.whatsappOptIn case final value?) 'whatsapp_opt_in': value,
      if (_$LangEnumMap[instance.preferredLang] case final value?)
        'preferred_lang': value,
    };

const _$LangEnumMap = {
  Lang.en: 'en',
  Lang.hi: 'hi',
  Lang.unknownDefaultOpenApi: 'unknown_default_open_api',
};
