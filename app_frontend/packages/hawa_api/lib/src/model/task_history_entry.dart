//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/task_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_history_entry.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskHistoryEntry {
  /// Returns a new [TaskHistoryEntry] instance.
  TaskHistoryEntry({

    required  this.status,

    required  this.at,

     this.source_,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: TaskStatus.unknownDefaultOpenApi,
  )


  final TaskStatus status;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskHistoryEntry &&
      other.status == status &&
      other.at == at &&
      other.source_ == source_;

    @override
    int get hashCode =>
        status.hashCode +
        at.hashCode +
        (source_ == null ? 0 : source_.hashCode);

  factory TaskHistoryEntry.fromJson(Map<String, dynamic> json) => _$TaskHistoryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$TaskHistoryEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

