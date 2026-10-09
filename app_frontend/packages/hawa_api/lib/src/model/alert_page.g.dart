// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertPage _$AlertPageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'AlertPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items'],
        );
        final val = AlertPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) => AlertItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$AlertPageToJson(AlertPage instance) => <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      if (instance.nextCursor case final value?) 'next_cursor': value,
    };
