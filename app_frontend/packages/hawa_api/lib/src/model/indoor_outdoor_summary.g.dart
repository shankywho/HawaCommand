// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indoor_outdoor_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndoorOutdoorSummary _$IndoorOutdoorSummaryFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'IndoorOutdoorSummary',
      json,
      ($checkedConvert) {
        final val = IndoorOutdoorSummary(
          meanRatioInOut: $checkedConvert(
              'mean_ratio_in_out', (v) => (v as num?)?.toDouble()),
          hoursIndoorAbove60: $checkedConvert(
              'hours_indoor_above_60', (v) => (v as num?)?.toDouble()),
          alertsSent:
              $checkedConvert('alerts_sent', (v) => (v as num?)?.toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'meanRatioInOut': 'mean_ratio_in_out',
        'hoursIndoorAbove60': 'hours_indoor_above_60',
        'alertsSent': 'alerts_sent'
      },
    );

Map<String, dynamic> _$IndoorOutdoorSummaryToJson(
        IndoorOutdoorSummary instance) =>
    <String, dynamic>{
      if (instance.meanRatioInOut case final value?) 'mean_ratio_in_out': value,
      if (instance.hoursIndoorAbove60 case final value?)
        'hours_indoor_above_60': value,
      if (instance.alertsSent case final value?) 'alerts_sent': value,
    };
