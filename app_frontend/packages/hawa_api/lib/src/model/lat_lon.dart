//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'lat_lon.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LatLon {
  /// Returns a new [LatLon] instance.
  LatLon({

    required  this.lat,

    required  this.lon,
  });

  @JsonKey(
    
    name: r'lat',
    required: true,
    includeIfNull: false,
  )


  final double lat;



  @JsonKey(
    
    name: r'lon',
    required: true,
    includeIfNull: false,
  )


  final double lon;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LatLon &&
      other.lat == lat &&
      other.lon == lon;

    @override
    int get hashCode =>
        lat.hashCode +
        lon.hashCode;

  factory LatLon.fromJson(Map<String, dynamic> json) => _$LatLonFromJson(json);

  Map<String, dynamic> toJson() => _$LatLonToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

