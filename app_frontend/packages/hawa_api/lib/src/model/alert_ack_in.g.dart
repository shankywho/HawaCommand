// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_ack_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertAckIn _$AlertAckInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AlertAckIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['at'],
        );
        final val = AlertAckIn(
          at: $checkedConvert('at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$AlertAckInToJson(AlertAckIn instance) =>
    <String, dynamic>{
      'at': instance.at.toIso8601String(),
    };
