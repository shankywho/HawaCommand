//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/shift_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_shift.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskShift {
  /// Returns a new [TaskShift] instance.
  TaskShift({

    required  this.id,

    required  this.status,

    required  this.start,

    required  this.end,

     this.startedAt,

     this.endedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ShiftStatus.unknownDefaultOpenApi,
  )


  final ShiftStatus status;



  @JsonKey(
    
    name: r'start',
    required: true,
    includeIfNull: false,
  )


  final DateTime start;



  @JsonKey(
    
    name: r'end',
    required: true,
    includeIfNull: false,
  )


  final DateTime end;



  @JsonKey(
    
    name: r'started_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? startedAt;



  @JsonKey(
    
    name: r'ended_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? endedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskShift &&
      other.id == id &&
      other.status == status &&
      other.start == start &&
      other.end == end &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode +
        start.hashCode +
        end.hashCode +
        (startedAt == null ? 0 : startedAt.hashCode) +
        (endedAt == null ? 0 : endedAt.hashCode);

  factory TaskShift.fromJson(Map<String, dynamic> json) => _$TaskShiftFromJson(json);

  Map<String, dynamic> toJson() => _$TaskShiftToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

