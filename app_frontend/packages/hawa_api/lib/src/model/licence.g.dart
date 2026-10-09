// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'licence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Licence _$LicenceFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Licence',
      json,
      ($checkedConvert) {
        final val = Licence(
          data: $checkedConvert('data', (v) => v as String?),
          osm: $checkedConvert('osm', (v) => v as String?),
          attribution: $checkedConvert('attribution', (v) => v as String?),
        );
        return val;
      },
    );

Map<String, dynamic> _$LicenceToJson(Licence instance) => <String, dynamic>{
      if (instance.data case final value?) 'data': value,
      if (instance.osm case final value?) 'osm': value,
      if (instance.attribution case final value?) 'attribution': value,
    };
