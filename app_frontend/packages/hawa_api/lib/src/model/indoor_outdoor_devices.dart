//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/device_state.dart';
import 'package:json_annotation/json_annotation.dart';

part 'indoor_outdoor_devices.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IndoorOutdoorDevices {
  /// Returns a new [IndoorOutdoorDevices] instance.
  IndoorOutdoorDevices({

    required  this.outdoor,

    required  this.indoor,
  });

  @JsonKey(
    
    name: r'outdoor',
    required: true,
    includeIfNull: false,
  )


  final DeviceState outdoor;



  @JsonKey(
    
    name: r'indoor',
    required: true,
    includeIfNull: false,
  )


  final DeviceState indoor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IndoorOutdoorDevices &&
      other.outdoor == outdoor &&
      other.indoor == indoor;

    @override
    int get hashCode =>
        outdoor.hashCode +
        indoor.hashCode;

  factory IndoorOutdoorDevices.fromJson(Map<String, dynamic> json) => _$IndoorOutdoorDevicesFromJson(json);

  Map<String, dynamic> toJson() => _$IndoorOutdoorDevicesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

