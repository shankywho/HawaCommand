// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvidencePhoto _$EvidencePhotoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EvidencePhoto',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['url', 'captured_at'],
        );
        final val = EvidencePhoto(
          url: $checkedConvert('url', (v) => v as String),
          capturedAt: $checkedConvert(
              'captured_at', (v) => DateTime.parse(v as String)),
          thumbUrl: $checkedConvert('thumb_url', (v) => v as String?),
          expiresAt: $checkedConvert('expires_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'capturedAt': 'captured_at',
        'thumbUrl': 'thumb_url',
        'expiresAt': 'expires_at'
      },
    );

Map<String, dynamic> _$EvidencePhotoToJson(EvidencePhoto instance) =>
    <String, dynamic>{
      'url': instance.url,
      'captured_at': instance.capturedAt.toIso8601String(),
      if (instance.thumbUrl case final value?) 'thumb_url': value,
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expires_at': value,
    };
