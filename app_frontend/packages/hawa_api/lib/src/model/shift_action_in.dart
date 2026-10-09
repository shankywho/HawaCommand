//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shift_action_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ShiftActionIn {
  /// Returns a new [ShiftActionIn] instance.
  ShiftActionIn({

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
    bool operator ==(Object other) => identical(this, other) || other is ShiftActionIn &&
      other.at == at &&
      other.location == location;

    @override
    int get hashCode =>
        at.hashCode +
        location.hashCode;

  factory ShiftActionIn.fromJson(Map<String, dynamic> json) => _$ShiftActionInFromJson(json);

  Map<String, dynamic> toJson() => _$ShiftActionInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

