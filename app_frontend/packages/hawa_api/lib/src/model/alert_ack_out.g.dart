// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_ack_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertAckOut _$AlertAckOutFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AlertAckOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['id', 'acked_at'],
        );
        final val = AlertAckOut(
          id: $checkedConvert('id', (v) => v as String),
          ackedAt:
              $checkedConvert('acked_at', (v) => DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {'ackedAt': 'acked_at'},
    );

Map<String, dynamic> _$AlertAckOutToJson(AlertAckOut instance) =>
    <String, dynamic>{
      'id': instance.id,
      'acked_at': instance.ackedAt.toIso8601String(),
    };
