//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'geo_line_string.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GeoLineString {
  /// Returns a new [GeoLineString] instance.
  GeoLineString({

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


  final List<List<double>> coordinates;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GeoLineString &&
      other.type == type &&
      other.coordinates == coordinates;

    @override
    int get hashCode =>
        type.hashCode +
        coordinates.hashCode;

  factory GeoLineString.fromJson(Map<String, dynamic> json) => _$GeoLineStringFromJson(json);

  Map<String, dynamic> toJson() => _$GeoLineStringToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

