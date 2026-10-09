// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presign_in.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PresignIn _$PresignInFromJson(Map<String, dynamic> json) => $checkedCreate(
      'PresignIn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'purpose',
            'content_type',
            'content_length',
            'sha256'
          ],
        );
        final val = PresignIn(
          purpose: $checkedConvert(
              'purpose',
              (v) => $enumDecode(_$UploadPurposeEnumMap, v,
                  unknownValue: UploadPurpose.unknownDefaultOpenApi)),
          contentType: $checkedConvert('content_type', (v) => v as String),
          contentLength:
              $checkedConvert('content_length', (v) => (v as num).toInt()),
          sha256: $checkedConvert('sha256', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'contentType': 'content_type',
        'contentLength': 'content_length'
      },
    );

Map<String, dynamic> _$PresignInToJson(PresignIn instance) => <String, dynamic>{
      'purpose': _$UploadPurposeEnumMap[instance.purpose]!,
      'content_type': instance.contentType,
      'content_length': instance.contentLength,
      'sha256': instance.sha256,
    };

const _$UploadPurposeEnumMap = {
  UploadPurpose.reportPhoto: 'report_photo',
  UploadPurpose.inspectionPhoto: 'inspection_photo',
  UploadPurpose.taskPhoto: 'task_photo',
  UploadPurpose.unknownDefaultOpenApi: 'unknown_default_open_api',
};
