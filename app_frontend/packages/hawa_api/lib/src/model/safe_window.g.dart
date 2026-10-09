// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafeWindow _$SafeWindowFromJson(Map<String, dynamic> json) => $checkedCreate(
      'SafeWindow',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['start', 'end', 'label'],
        );
        final val = SafeWindow(
          start: $checkedConvert('start', (v) => DateTime.parse(v as String)),
          end: $checkedConvert('end', (v) => DateTime.parse(v as String)),
          label: $checkedConvert(
              'label',
              (v) => $enumDecode(_$SafeWindowLabelEnumMap, v,
                  unknownValue: SafeWindowLabel.unknownDefaultOpenApi)),
          pm25P10: $checkedConvert('pm25_p10', (v) => (v as num?)?.toDouble()),
          pm25P50: $checkedConvert('pm25_p50', (v) => (v as num?)?.toDouble()),
          pm25P90: $checkedConvert('pm25_p90', (v) => (v as num?)?.toDouble()),
          confidence:
              $checkedConvert('confidence', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'pm25P10': 'pm25_p10',
        'pm25P50': 'pm25_p50',
        'pm25P90': 'pm25_p90'
      },
    );

Map<String, dynamic> _$SafeWindowToJson(SafeWindow instance) =>
    <String, dynamic>{
      'start': instance.start.toIso8601String(),
      'end': instance.end.toIso8601String(),
      'label': _$SafeWindowLabelEnumMap[instance.label]!,
      if (instance.pm25P10 case final value?) 'pm25_p10': value,
      if (instance.pm25P50 case final value?) 'pm25_p50': value,
      if (instance.pm25P90 case final value?) 'pm25_p90': value,
      if (instance.confidence case final value?) 'confidence': value,
    };

const _$SafeWindowLabelEnumMap = {
  SafeWindowLabel.safe: 'safe',
  SafeWindowLabel.borderline: 'borderline',
  SafeWindowLabel.avoid: 'avoid',
  SafeWindowLabel.unknownDefaultOpenApi: 'unknown_default_open_api',
};
