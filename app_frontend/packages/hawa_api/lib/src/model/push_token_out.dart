//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/push_platform.dart';
import 'package:json_annotation/json_annotation.dart';

part 'push_token_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PushTokenOut {
  /// Returns a new [PushTokenOut] instance.
  PushTokenOut({

    required  this.id,

    required  this.platform,

     this.lastSeenAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  unknownEnumValue: PushPlatform.unknownDefaultOpenApi,
  )


  final PushPlatform platform;



  @JsonKey(
    
    name: r'last_seen_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? lastSeenAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PushTokenOut &&
      other.id == id &&
      other.platform == platform &&
      other.lastSeenAt == lastSeenAt;

    @override
    int get hashCode =>
        id.hashCode +
        platform.hashCode +
        (lastSeenAt == null ? 0 : lastSeenAt.hashCode);

  factory PushTokenOut.fromJson(Map<String, dynamic> json) => _$PushTokenOutFromJson(json);

  Map<String, dynamic> toJson() => _$PushTokenOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

