// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiet_hours.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuietHours _$QuietHoursFromJson(Map<String, dynamic> json) => $checkedCreate(
      'QuietHours',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['start', 'end'],
        );
        final val = QuietHours(
          start: $checkedConvert('start', (v) => v as String),
          end: $checkedConvert('end', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$QuietHoursToJson(QuietHours instance) =>
    <String, dynamic>{
      'start': instance.start,
      'end': instance.end,
    };
