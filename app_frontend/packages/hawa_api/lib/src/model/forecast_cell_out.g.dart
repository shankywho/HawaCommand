// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_cell_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastCellOut _$ForecastCellOutFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ForecastCellOut',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'cell_id',
            'pollutant',
            'issued_at',
            'series',
            'is_simulated'
          ],
        );
        final val = ForecastCellOut(
          cellId: $checkedConvert('cell_id', (v) => v as String),
          pollutant: $checkedConvert(
              'pollutant',
              (v) => $enumDecode(_$PollutantEnumMap, v,
                  unknownValue: Pollutant.unknownDefaultOpenApi)),
          issuedAt:
              $checkedConvert('issued_at', (v) => DateTime.parse(v as String)),
          series: $checkedConvert(
              'series',
              (v) => (v as List<dynamic>)
                  .map((e) => ForecastPoint.fromJson(e as Map<String, dynamic>))
                  .toList()),
          isSimulated: $checkedConvert('is_simulated', (v) => v as bool),
          requestedCellId:
              $checkedConvert('requested_cell_id', (v) => v as String?),
          runId: $checkedConvert('run_id', (v) => v as String?),
          modelVersion: $checkedConvert('model_version', (v) => v as String?),
          daily: $checkedConvert(
              'daily',
              (v) => (v as List<dynamic>?)
                  ?.map(
                      (e) => ForecastDaily.fromJson(e as Map<String, dynamic>))
                  .toList()),
        );
        return val;
      },
      fieldKeyMap: const {
        'cellId': 'cell_id',
        'issuedAt': 'issued_at',
        'isSimulated': 'is_simulated',
        'requestedCellId': 'requested_cell_id',
        'runId': 'run_id',
        'modelVersion': 'model_version'
      },
    );

Map<String, dynamic> _$ForecastCellOutToJson(ForecastCellOut instance) =>
    <String, dynamic>{
      'cell_id': instance.cellId,
      'pollutant': _$PollutantEnumMap[instance.pollutant]!,
      'issued_at': instance.issuedAt.toIso8601String(),
      'series': instance.series.map((e) => e.toJson()).toList(),
      'is_simulated': instance.isSimulated,
      if (instance.requestedCellId case final value?)
        'requested_cell_id': value,
      if (instance.runId case final value?) 'run_id': value,
      if (instance.modelVersion case final value?) 'model_version': value,
      if (instance.daily?.map((e) => e.toJson()).toList() case final value?)
        'daily': value,
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
