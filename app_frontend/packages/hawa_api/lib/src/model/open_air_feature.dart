//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/geo_polygon.dart';
import 'package:hawa_api/src/model/open_air_properties.dart';
import 'package:json_annotation/json_annotation.dart';

part 'open_air_feature.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OpenAirFeature {
  /// Returns a new [OpenAirFeature] instance.
  OpenAirFeature({

    required  this.type,

    required  this.id,

    required  this.geometry,

    required  this.properties,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'geometry',
    required: true,
    includeIfNull: false,
  )


  final GeoPolygon geometry;



  @JsonKey(
    
    name: r'properties',
    required: true,
    includeIfNull: false,
  )


  final OpenAirProperties properties;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OpenAirFeature &&
      other.type == type &&
      other.id == id &&
      other.geometry == geometry &&
      other.properties == properties;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode +
        geometry.hashCode +
        properties.hashCode;

  factory OpenAirFeature.fromJson(Map<String, dynamic> json) => _$OpenAirFeatureFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAirFeatureToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

