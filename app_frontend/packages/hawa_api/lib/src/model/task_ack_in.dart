//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'task_ack_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskAckIn {
  /// Returns a new [TaskAckIn] instance.
  TaskAckIn({

    required  this.at,
  });

  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskAckIn &&
      other.at == at;

    @override
    int get hashCode =>
        at.hashCode;

  factory TaskAckIn.fromJson(Map<String, dynamic> json) => _$TaskAckInFromJson(json);

  Map<String, dynamic> toJson() => _$TaskAckInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

