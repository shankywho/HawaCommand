//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'alert_ack_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlertAckOut {
  /// Returns a new [AlertAckOut] instance.
  AlertAckOut({

    required  this.id,

    required  this.ackedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'acked_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime ackedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlertAckOut &&
      other.id == id &&
      other.ackedAt == ackedAt;

    @override
    int get hashCode =>
        id.hashCode +
        ackedAt.hashCode;

  factory AlertAckOut.fromJson(Map<String, dynamic> json) => _$AlertAckOutFromJson(json);

  Map<String, dynamic> toJson() => _$AlertAckOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

