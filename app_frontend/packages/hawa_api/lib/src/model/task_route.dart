//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/geo_line_string.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_route.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskRoute {
  /// Returns a new [TaskRoute] instance.
  TaskRoute({

    required  this.routeId,

    required  this.version,

    required  this.geometry,

     this.planId,

     this.bbox,

     this.distanceKm,
  });

  @JsonKey(
    
    name: r'route_id',
    required: true,
    includeIfNull: false,
  )


  final String routeId;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'geometry',
    required: true,
    includeIfNull: false,
  )


  final GeoLineString geometry;



  @JsonKey(
    
    name: r'plan_id',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



  @JsonKey(
    
    name: r'bbox',
    required: false,
    includeIfNull: false,
  )


  final List<double>? bbox;



  @JsonKey(
    
    name: r'distance_km',
    required: false,
    includeIfNull: false,
  )


  final double? distanceKm;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskRoute &&
      other.routeId == routeId &&
      other.version == version &&
      other.geometry == geometry &&
      other.planId == planId &&
      other.bbox == bbox &&
      other.distanceKm == distanceKm;

    @override
    int get hashCode =>
        routeId.hashCode +
        version.hashCode +
        geometry.hashCode +
        (planId == null ? 0 : planId.hashCode) +
        (bbox == null ? 0 : bbox.hashCode) +
        (distanceKm == null ? 0 : distanceKm.hashCode);

  factory TaskRoute.fromJson(Map<String, dynamic> json) => _$TaskRouteFromJson(json);

  Map<String, dynamic> toJson() => _$TaskRouteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

