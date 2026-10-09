// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_action_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftActionIn _$ShiftActionInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ShiftActionIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['at'],
        );
        final val = ShiftActionIn(
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
          location: $checkedConvert(
              'location',
              (v) => v == null
                  ? null
                  : GeoPoint.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
    );

Map<String, dynamic> _$ShiftActionInToJson(ShiftActionIn instance) =>
    <String, dynamic>{
      'at': instance.at.toIso8601String(),
      if (instance.location?.toJson() case final value?) 'location': value,
    };
