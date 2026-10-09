// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolRef _$SchoolRefFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SchoolRef',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['school_id', 'name'],
        );
        final val = SchoolRef(
          schoolId: $checkedConvert('school_id', (v) => v as String),
          name: $checkedConvert('name', (v) => v as String),
          nameHi: $checkedConvert('name_hi', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'schoolId': 'school_id', 'nameHi': 'name_hi'},
    );

Map<String, dynamic> _$SchoolRefToJson(SchoolRef instance) => <String, dynamic>{
      'school_id': instance.schoolId,
      'name': instance.name,
      if (instance.nameHi case final value?) 'name_hi': value,
    };
