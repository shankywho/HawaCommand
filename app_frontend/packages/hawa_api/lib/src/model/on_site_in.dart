//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:json_annotation/json_annotation.dart';

part 'on_site_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OnSiteIn {
  /// Returns a new [OnSiteIn] instance.
  OnSiteIn({

    required  this.at,

     this.location,
  });

  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;



  @JsonKey(
    
    name: r'location',
    required: false,
    includeIfNull: false,
  )


  final GeoPoint? location;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OnSiteIn &&
      other.at == at &&
      other.location == location;

    @override
    int get hashCode =>
        at.hashCode +
        location.hashCode;

  factory OnSiteIn.fromJson(Map<String, dynamic> json) => _$OnSiteInFromJson(json);

  Map<String, dynamic> toJson() => _$OnSiteInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

