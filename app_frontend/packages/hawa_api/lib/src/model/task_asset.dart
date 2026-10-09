//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/device_status.dart';
import 'package:hawa_api/src/model/asset_type.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_asset.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskAsset {
  /// Returns a new [TaskAsset] instance.
  TaskAsset({

    required  this.id,

    required  this.type,

    required  this.label,

    required  this.isSimulated,

     this.tagDeviceId,

     this.tagStatus,

     this.tagLastSeenAt,

     this.capacityLitres,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AssetType.unknownDefaultOpenApi,
  )


  final AssetType type;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'tag_device_id',
    required: false,
    includeIfNull: false,
  )


  final String? tagDeviceId;



  @JsonKey(
    
    name: r'tag_status',
    required: false,
    includeIfNull: false,
  unknownEnumValue: DeviceStatus.unknownDefaultOpenApi,
  )


  final DeviceStatus? tagStatus;



  @JsonKey(
    
    name: r'tag_last_seen_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? tagLastSeenAt;



  @JsonKey(
    
    name: r'capacity_litres',
    required: false,
    includeIfNull: false,
  )


  final double? capacityLitres;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskAsset &&
      other.id == id &&
      other.type == type &&
      other.label == label &&
      other.isSimulated == isSimulated &&
      other.tagDeviceId == tagDeviceId &&
      other.tagStatus == tagStatus &&
      other.tagLastSeenAt == tagLastSeenAt &&
      other.capacityLitres == capacityLitres;

    @override
    int get hashCode =>
        id.hashCode +
        type.hashCode +
        label.hashCode +
        isSimulated.hashCode +
        (tagDeviceId == null ? 0 : tagDeviceId.hashCode) +
        tagStatus.hashCode +
        (tagLastSeenAt == null ? 0 : tagLastSeenAt.hashCode) +
        (capacityLitres == null ? 0 : capacityLitres.hashCode);

  factory TaskAsset.fromJson(Map<String, dynamic> json) => _$TaskAssetFromJson(json);

  Map<String, dynamic> toJson() => _$TaskAssetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

