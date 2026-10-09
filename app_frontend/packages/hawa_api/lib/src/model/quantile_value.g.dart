// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantile_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuantileValue _$QuantileValueFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'QuantileValue',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['p50'],
        );
        final val = QuantileValue(
          p50: $checkedConvert('p50', (v) => (v as num).toDouble()),
          p10: $checkedConvert('p10', (v) => (v as num?)?.toDouble()),
          p90: $checkedConvert('p90', (v) => (v as num?)?.toDouble()),
          at: $checkedConvert(
              'at', (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
    );

Map<String, dynamic> _$QuantileValueToJson(QuantileValue instance) =>
    <String, dynamic>{
      'p50': instance.p50,
      if (instance.p10 case final value?) 'p10': value,
      if (instance.p90 case final value?) 'p90': value,
      if (instance.at?.toIso8601String() case final value?) 'at': value,
    };
