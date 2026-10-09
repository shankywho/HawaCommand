//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'location_ping.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocationPing {
  /// Returns a new [LocationPing] instance.
  LocationPing({

    required  this.ts,

    required  this.lat,

    required  this.lon,

     this.accuracyM,

     this.speedKmh,
  });

  @JsonKey(
    
    name: r'ts',
    required: true,
    includeIfNull: false,
  )


  final DateTime ts;



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



  @JsonKey(
    
    name: r'accuracy_m',
    required: false,
    includeIfNull: false,
  )


  final double? accuracyM;



  @JsonKey(
    
    name: r'speed_kmh',
    required: false,
    includeIfNull: false,
  )


  final double? speedKmh;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocationPing &&
      other.ts == ts &&
      other.lat == lat &&
      other.lon == lon &&
      other.accuracyM == accuracyM &&
      other.speedKmh == speedKmh;

    @override
    int get hashCode =>
        ts.hashCode +
        lat.hashCode +
        lon.hashCode +
        (accuracyM == null ? 0 : accuracyM.hashCode) +
        (speedKmh == null ? 0 : speedKmh.hashCode);

  factory LocationPing.fromJson(Map<String, dynamic> json) => _$LocationPingFromJson(json);

  Map<String, dynamic> toJson() => _$LocationPingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

