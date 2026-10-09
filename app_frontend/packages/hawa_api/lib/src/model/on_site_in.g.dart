// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'on_site_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnSiteIn _$OnSiteInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'OnSiteIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['at'],
        );
        final val = OnSiteIn(
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

Map<String, dynamic> _$OnSiteInToJson(OnSiteIn instance) => <String, dynamic>{
      'at': instance.at.toIso8601String(),
      if (instance.location?.toJson() case final value?) 'location': value,
    };
