// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidence_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvidenceSummary _$EvidenceSummaryFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'EvidenceSummary',
      json,
      ($checkedConvert) {
        final val = EvidenceSummary(
          spikeRatio:
              $checkedConvert('spike_ratio', (v) => (v as num?)?.toDouble()),
          photoLabel: $checkedConvert(
              'photo_label',
              (v) => $enumDecodeNullable(_$CauseLabelEnumMap, v,
                  unknownValue: CauseLabel.unknownDefaultOpenApi)),
          photoConf:
              $checkedConvert('photo_conf', (v) => (v as num?)?.toDouble()),
          firePoints:
              $checkedConvert('fire_points', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'spikeRatio': 'spike_ratio',
        'photoLabel': 'photo_label',
        'photoConf': 'photo_conf',
        'firePoints': 'fire_points'
      },
    );

Map<String, dynamic> _$EvidenceSummaryToJson(EvidenceSummary instance) =>
    <String, dynamic>{
      if (instance.spikeRatio case final value?) 'spike_ratio': value,
      if (_$CauseLabelEnumMap[instance.photoLabel] case final value?)
        'photo_label': value,
      if (instance.photoConf case final value?) 'photo_conf': value,
      if (instance.firePoints case final value?) 'fire_points': value,
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
