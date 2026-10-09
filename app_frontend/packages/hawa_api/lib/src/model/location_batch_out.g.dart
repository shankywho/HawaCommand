// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_batch_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationBatchOut _$LocationBatchOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LocationBatchOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['accepted'],
        );
        final val = LocationBatchOut(
          accepted: $checkedConvert('accepted', (v) => (v as num).toInt()),
        );
        return val;
      },
    );

Map<String, dynamic> _$LocationBatchOutToJson(LocationBatchOut instance) =>
    <String, dynamic>{
      'accepted': instance.accepted,
    };
