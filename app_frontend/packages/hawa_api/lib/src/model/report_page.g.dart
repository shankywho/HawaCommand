// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportPage _$ReportPageFromJson(Map<String, dynamic> json) => $checkedCreate(
      'ReportPage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['items'],
        );
        final val = ReportPage(
          items: $checkedConvert(
              'items',
              (v) => (v as List<dynamic>)
                  .map(
                      (e) => ReportListItem.fromJson(e as Map<String, dynamic>))
                  .toList()),
          nextCursor: $checkedConvert('next_cursor', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {'nextCursor': 'next_cursor'},
    );

Map<String, dynamic> _$ReportPageToJson(ReportPage instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      if (instance.nextCursor case final value?) 'next_cursor': value,
    };
