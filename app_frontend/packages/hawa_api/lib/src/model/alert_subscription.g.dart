// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertSubscription _$AlertSubscriptionFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'AlertSubscription',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['radius_m', 'kinds'],
        );
        final val = AlertSubscription(
          radiusM: $checkedConvert('radius_m', (v) => (v as num).toInt()),
          kinds: $checkedConvert(
              'kinds',
              (v) => (v as List<dynamic>)
                  .map((e) => $enumDecode(_$AlertKindEnumMap, e))
                  .toList()),
          home: $checkedConvert(
              'home',
              (v) => v == null
                  ? null
                  : LatLon.fromJson(v as Map<String, dynamic>)),
          placeName: $checkedConvert(
              'place_name',
              (v) => v == null
                  ? null
                  : LocalizedText.fromJson(v as Map<String, dynamic>)),
          quietHours: $checkedConvert(
              'quiet_hours',
              (v) => v == null
                  ? null
                  : QuietHours.fromJson(v as Map<String, dynamic>)),
        );
        return val;
      },
      fieldKeyMap: const {
        'radiusM': 'radius_m',
        'placeName': 'place_name',
        'quietHours': 'quiet_hours'
      },
    );

Map<String, dynamic> _$AlertSubscriptionToJson(AlertSubscription instance) =>
    <String, dynamic>{
      'radius_m': instance.radiusM,
      'kinds': instance.kinds.map((e) => _$AlertKindEnumMap[e]!).toList(),
      if (instance.home?.toJson() case final value?) 'home': value,
      if (instance.placeName?.toJson() case final value?) 'place_name': value,
      if (instance.quietHours?.toJson() case final value?) 'quiet_hours': value,
    };

const _$AlertKindEnumMap = {
  AlertKind.pollutantWarning: 'pollutant_warning',
  AlertKind.safeWindow: 'safe_window',
  AlertKind.routeAssignment: 'route_assignment',
  AlertKind.inspectionTarget: 'inspection_target',
  AlertKind.grapOutlook: 'grap_outlook',
  AlertKind.reportOutcome: 'report_outcome',
  AlertKind.deviceHealth: 'device_health',
  AlertKind.routeChanged: 'route_changed',
  AlertKind.taskDoneAuto: 'task_done_auto',
  AlertKind.unknownDefaultOpenApi: 'unknown_default_open_api',
};
