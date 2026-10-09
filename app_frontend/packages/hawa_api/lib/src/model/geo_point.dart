//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'geo_point.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GeoPoint {
  /// Returns a new [GeoPoint] instance.
  GeoPoint({

    required  this.type,

    required  this.coordinates,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'coordinates',
    required: true,
    includeIfNull: false,
  )


  final List<double> coordinates;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GeoPoint &&
      other.type == type &&
      other.coordinates == coordinates;

    @override
    int get hashCode =>
        type.hashCode +
        coordinates.hashCode;

  factory GeoPoint.fromJson(Map<String, dynamic> json) => _$GeoPointFromJson(json);

  Map<String, dynamic> toJson() => _$GeoPointToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

