//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/intervention_source.dart';
import 'package:hawa_api/src/model/task_status.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/skip_reason.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_status_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskStatusIn {
  /// Returns a new [TaskStatusIn] instance.
  TaskStatusIn({

    required  this.status,

    required  this.clientTs,

     this.source_,

     this.reason,

     this.note,

     this.litres,

     this.s3Keys,

     this.location,

     this.accuracyM,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: TaskStatus.unknownDefaultOpenApi,
  )


  final TaskStatus status;



  @JsonKey(
    
    name: r'client_ts',
    required: true,
    includeIfNull: false,
  )


  final DateTime clientTs;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  unknownEnumValue: InterventionSource.unknownDefaultOpenApi,
  )


  final InterventionSource? source_;



  @JsonKey(
    
    name: r'reason',
    required: false,
    includeIfNull: false,
  unknownEnumValue: SkipReason.unknownDefaultOpenApi,
  )


  final SkipReason? reason;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;



  @JsonKey(
    
    name: r'litres',
    required: false,
    includeIfNull: false,
  )


  final double? litres;



  @JsonKey(
    
    name: r's3_keys',
    required: false,
    includeIfNull: false,
  )


  final List<String>? s3Keys;



  @JsonKey(
    
    name: r'location',
    required: false,
    includeIfNull: false,
  )


  final GeoPoint? location;



  @JsonKey(
    
    name: r'accuracy_m',
    required: false,
    includeIfNull: false,
  )


  final double? accuracyM;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskStatusIn &&
      other.status == status &&
      other.clientTs == clientTs &&
      other.source_ == source_ &&
      other.reason == reason &&
      other.note == note &&
      other.litres == litres &&
      other.s3Keys == s3Keys &&
      other.location == location &&
      other.accuracyM == accuracyM;

    @override
    int get hashCode =>
        status.hashCode +
        clientTs.hashCode +
        source_.hashCode +
        reason.hashCode +
        (note == null ? 0 : note.hashCode) +
        (litres == null ? 0 : litres.hashCode) +
        (s3Keys == null ? 0 : s3Keys.hashCode) +
        location.hashCode +
        (accuracyM == null ? 0 : accuracyM.hashCode);

  factory TaskStatusIn.fromJson(Map<String, dynamic> json) => _$TaskStatusInFromJson(json);

  Map<String, dynamic> toJson() => _$TaskStatusInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

