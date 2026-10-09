//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/task_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_ack_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskAckOut {
  /// Returns a new [TaskAckOut] instance.
  TaskAckOut({

    required  this.taskId,

    required  this.status,

     this.acknowledgedAt,
  });

  @JsonKey(
    
    name: r'task_id',
    required: true,
    includeIfNull: false,
  )


  final String taskId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: TaskStatus.unknownDefaultOpenApi,
  )


  final TaskStatus status;



  @JsonKey(
    
    name: r'acknowledged_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? acknowledgedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskAckOut &&
      other.taskId == taskId &&
      other.status == status &&
      other.acknowledgedAt == acknowledgedAt;

    @override
    int get hashCode =>
        taskId.hashCode +
        status.hashCode +
        (acknowledgedAt == null ? 0 : acknowledgedAt.hashCode);

  factory TaskAckOut.fromJson(Map<String, dynamic> json) => _$TaskAckOutFromJson(json);

  Map<String, dynamic> toJson() => _$TaskAckOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

