// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spike_evidence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpikeEvidence _$SpikeEvidenceFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SpikeEvidence',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['pollutant', 'baseline', 'peak', 'series'],
        );
        final val = SpikeEvidence(
          pollutant: $checkedConvert(
              'pollutant',
              (v) => $enumDecode(_$PollutantEnumMap, v,
                  unknownValue: Pollutant.unknownDefaultOpenApi)),
          baseline: $checkedConvert('baseline', (v) => (v as num).toDouble()),
          peak: $checkedConvert('peak', (v) => (v as num).toDouble()),
          series: $checkedConvert(
              'series',
              (v) => (v as List<dynamic>)
                  .map((e) => SeriesPoint.fromJson(e as Map<String, dynamic>))
                  .toList()),
          deviceId: $checkedConvert('device_id', (v) => v as String?),
          vehicleLabel: $checkedConvert('vehicle_label', (v) => v as String?),
          durationS: $checkedConvert('duration_s', (v) => (v as num?)?.toInt()),
          detectedAt: $checkedConvert('detected_at',
              (v) => v == null ? null : DateTime.parse(v as String)),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceId': 'device_id',
        'vehicleLabel': 'vehicle_label',
        'durationS': 'duration_s',
        'detectedAt': 'detected_at'
      },
    );

Map<String, dynamic> _$SpikeEvidenceToJson(SpikeEvidence instance) =>
    <String, dynamic>{
      'pollutant': _$PollutantEnumMap[instance.pollutant]!,
      'baseline': instance.baseline,
      'peak': instance.peak,
      'series': instance.series.map((e) => e.toJson()).toList(),
      if (instance.deviceId case final value?) 'device_id': value,
      if (instance.vehicleLabel case final value?) 'vehicle_label': value,
      if (instance.durationS case final value?) 'duration_s': value,
      if (instance.detectedAt?.toIso8601String() case final value?)
        'detected_at': value,
    };

const _$PollutantEnumMap = {
  Pollutant.pm1: 'pm1',
  Pollutant.pm25: 'pm25',
  Pollutant.pm10: 'pm10',
  Pollutant.no2: 'no2',
  Pollutant.co: 'co',
  Pollutant.nh3: 'nh3',
  Pollutant.voc: 'voc',
  Pollutant.co2: 'co2',
  Pollutant.unknownDefaultOpenApi: 'unknown_default_open_api',
};
