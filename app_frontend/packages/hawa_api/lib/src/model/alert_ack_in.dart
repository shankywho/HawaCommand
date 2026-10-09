//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'alert_ack_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlertAckIn {
  /// Returns a new [AlertAckIn] instance.
  AlertAckIn({

    required  this.at,
  });

  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlertAckIn &&
      other.at == at;

    @override
    int get hashCode =>
        at.hashCode;

  factory AlertAckIn.fromJson(Map<String, dynamic> json) => _$AlertAckInFromJson(json);

  Map<String, dynamic> toJson() => _$AlertAckInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

