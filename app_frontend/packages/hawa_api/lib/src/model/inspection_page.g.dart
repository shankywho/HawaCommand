// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InspectionPage _$InspectionPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InspectionPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items'],
        );
        final val = InspectionPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map((e) =>
                      InspectionListItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$InspectionPageToJson(InspectionPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      if (instance.nextCursor case final value?) 'next_cursor': value,
    };
