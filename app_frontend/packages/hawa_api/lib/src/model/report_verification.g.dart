// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportVerification _$ReportVerificationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportVerification',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['verified'],
        );
        final val = ReportVerification(
          verified: $checkedConvert('verified', (v) => v as bool),
          label: $checkedConvert(
              'label',
              (v) => $enumDecodeNullable(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          confidence:
              $checkedConvert('confidence', (v) => (v as num?)?.toDouble()),
          verifiedAt: $checkedConvert('verified_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
          modelVersion: $checkedConvert('model_version', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'verifiedAt': 'verified_at',
        'modelVersion': 'model_version'
      },
    );

Map<String, dynamic> _$ReportVerificationToJson(ReportVerification instance) =>
    <String, dynamic>{
      'verified': instance.verified,
      if (_$CauseLabelEnumMap[instance.label] case final value?) 'label': value,
      if (instance.confidence case final value?) 'confidence': value,
      if (instance.verifiedAt?.toIso8601String() case final value?)
        'verified_at': value,
      if (instance.modelVersion case final value?) 'model_version': value,
    };

const _$CauseLabelEnumMap = {
  CauseLabel.dust: 'dust',
  CauseLabel.traffic: 'traffic',
  CauseLabel.burning: 'burning',
  CauseLabel.regionalSmoke: 'regional_smoke',
  CauseLabel.mixed: 'mixed',
  CauseLabel.unknown: 'unknown',
  CauseLabel.unknownDefaultOpenApi: 'unknown_default_open_api',
};
