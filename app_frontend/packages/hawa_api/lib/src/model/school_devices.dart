//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'school_devices.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolDevices {
  /// Returns a new [SchoolDevices] instance.
  SchoolDevices({

    required  this.outdoor,

    required  this.indoor,
  });

  @JsonKey(
    
    name: r'outdoor',
    required: true,
    includeIfNull: false,
  )


  final String outdoor;



  @JsonKey(
    
    name: r'indoor',
    required: true,
    includeIfNull: false,
  )


  final String indoor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SchoolDevices &&
      other.outdoor == outdoor &&
      other.indoor == indoor;

    @override
    int get hashCode =>
        outdoor.hashCode +
        indoor.hashCode;

  factory SchoolDevices.fromJson(Map<String, dynamic> json) => _$SchoolDevicesFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolDevicesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

