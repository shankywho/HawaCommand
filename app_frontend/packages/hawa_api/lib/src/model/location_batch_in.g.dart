// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_batch_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationBatchIn _$LocationBatchInFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'LocationBatchIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['pings'],
        );
        final val = LocationBatchIn(
          pings: $checkedConvert(
              'pings',
              (v) => (v as List<dynamic>)
                  .map((e) => LocationPing.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
    );

Map<String, dynamic> _$LocationBatchInToJson(LocationBatchIn instance) =>
    <String, dynamic>{
      'pings': instance.pings.map((e) => e.toJson()).toList(),
    };
