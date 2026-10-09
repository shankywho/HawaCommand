// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskRoute _$TaskRouteFromJson(Map<String, dynamic> json) => $checkedCreate(
      'TaskRoute',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['route_id', 'version', 'geometry'],
        );
        final val = TaskRoute(
          routeId: $checkedConvert('route_id', (v) => v as String),
          version: $checkedConvert('version', (v) => (v as num).toInt()),
          geometry: $checkedConvert('geometry',
              (v) => GeoLineString.fromJson(v as Map<String, dynamic>)),
          planId: $checkedConvert('plan_id', (v) => v as String?),
          bbox: $checkedConvert(
              'bbox',
              (v) => (v as List<dynamic>?)
                  ?.map((e) => (e as num).toDouble())
                  .toList()),
          distanceKm:
              $checkedConvert('distance_km', (v) => (v as num?)?.toDouble()),
        );
        return val;
      },
      fieldKeyMap: const {
        'routeId': 'route_id',
        'planId': 'plan_id',
        'distanceKm': 'distance_km'
      },
    );

Map<String, dynamic> _$TaskRouteToJson(TaskRoute instance) => <String, dynamic>{
      'route_id': instance.routeId,
      'version': instance.version,
      'geometry': instance.geometry.toJson(),
      if (instance.planId case final value?) 'plan_id': value,
      if (instance.bbox case final value?) 'bbox': value,
      if (instance.distanceKm case final value?) 'distance_km': value,
    };
