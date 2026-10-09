//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/intervention_source.dart';
import 'package:hawa_api/src/model/task_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_status_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskStatusOut {
  /// Returns a new [TaskStatusOut] instance.
  TaskStatusOut({

    required  this.taskId,

    required  this.status,

     this.statusSource,

     this.interventionId,

     this.evidenceLevel,

     this.verifyAfter,
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
    
    name: r'status_source',
    required: false,
    includeIfNull: false,
  unknownEnumValue: InterventionSource.unknownDefaultOpenApi,
  )


  final InterventionSource? statusSource;



  @JsonKey(
    
    name: r'intervention_id',
    required: false,
    includeIfNull: false,
  )


  final String? interventionId;



  @JsonKey(
    
    name: r'evidence_level',
    required: false,
    includeIfNull: false,
  )


  final String? evidenceLevel;



  @JsonKey(
    
    name: r'verify_after',
    required: false,
    includeIfNull: false,
  )


  final DateTime? verifyAfter;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskStatusOut &&
      other.taskId == taskId &&
      other.status == status &&
      other.statusSource == statusSource &&
      other.interventionId == interventionId &&
      other.evidenceLevel == evidenceLevel &&
      other.verifyAfter == verifyAfter;

    @override
    int get hashCode =>
        taskId.hashCode +
        status.hashCode +
        statusSource.hashCode +
        (interventionId == null ? 0 : interventionId.hashCode) +
        (evidenceLevel == null ? 0 : evidenceLevel.hashCode) +
        (verifyAfter == null ? 0 : verifyAfter.hashCode);

  factory TaskStatusOut.fromJson(Map<String, dynamic> json) => _$TaskStatusOutFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatusOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

