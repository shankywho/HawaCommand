//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/device_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_state.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceState {
  /// Returns a new [DeviceState] instance.
  DeviceState({

    required  this.deviceId,

    required  this.status,

     this.lastSeenAt,
  });

  @JsonKey(
    
    name: r'device_id',
    required: true,
    includeIfNull: false,
  )


  final String deviceId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: DeviceStatus.unknownDefaultOpenApi,
  )


  final DeviceStatus status;



  @JsonKey(
    
    name: r'last_seen_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? lastSeenAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceState &&
      other.deviceId == deviceId &&
      other.status == status &&
      other.lastSeenAt == lastSeenAt;

    @override
    int get hashCode =>
        deviceId.hashCode +
        status.hashCode +
        (lastSeenAt == null ? 0 : lastSeenAt.hashCode);

  factory DeviceState.fromJson(Map<String, dynamic> json) => _$DeviceStateFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceStateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

