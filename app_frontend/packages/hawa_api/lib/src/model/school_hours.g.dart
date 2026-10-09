// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SchoolHours _$SchoolHoursFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SchoolHours',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['day_start', 'day_end'],
        );
        final val = SchoolHours(
          dayStart: $checkedConvert('day_start', (v) => v as String),
          dayEnd: $checkedConvert('day_end', (v) => v as String),
          assembly: $checkedConvert('assembly', (v) => v as String?),
          timezone: $checkedConvert('timezone', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'dayStart': 'day_start', 'dayEnd': 'day_end'},
    );

Map<String, dynamic> _$SchoolHoursToJson(SchoolHours instance) =>
    <String, dynamic>{
      'day_start': instance.dayStart,
      'day_end': instance.dayEnd,
      if (instance.assembly case final value?) 'assembly': value,
      if (instance.timezone case final value?) 'timezone': value,
    };
