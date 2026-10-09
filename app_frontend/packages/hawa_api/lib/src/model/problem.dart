//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/problem_field_error.dart';
import 'package:json_annotation/json_annotation.dart';

part 'problem.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Problem {
  /// Returns a new [Problem] instance.
  Problem({

    required  this.type,

    required  this.title,

    required  this.status,

    required  this.code,

     this.detail,

     this.instance,

     this.requestId,

     this.errors,

     this.currentVersion,

     this.allowed,

     this.retryAfter,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final int status;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'detail',
    required: false,
    includeIfNull: false,
  )


  final String? detail;



  @JsonKey(
    
    name: r'instance',
    required: false,
    includeIfNull: false,
  )


  final String? instance;



  @JsonKey(
    
    name: r'request_id',
    required: false,
    includeIfNull: false,
  )


  final String? requestId;



  @JsonKey(
    
    name: r'errors',
    required: false,
    includeIfNull: false,
  )


  final List<ProblemFieldError>? errors;



  @JsonKey(
    
    name: r'current_version',
    required: false,
    includeIfNull: false,
  )


  final int? currentVersion;



  @JsonKey(
    
    name: r'allowed',
    required: false,
    includeIfNull: false,
  )


  final List<String>? allowed;



  @JsonKey(
    
    name: r'retry_after',
    required: false,
    includeIfNull: false,
  )


  final int? retryAfter;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Problem &&
      other.type == type &&
      other.title == title &&
      other.status == status &&
      other.code == code &&
      other.detail == detail &&
      other.instance == instance &&
      other.requestId == requestId &&
      other.errors == errors &&
      other.currentVersion == currentVersion &&
      other.allowed == allowed &&
      other.retryAfter == retryAfter;

    @override
    int get hashCode =>
        type.hashCode +
        title.hashCode +
        status.hashCode +
        code.hashCode +
        (detail == null ? 0 : detail.hashCode) +
        (instance == null ? 0 : instance.hashCode) +
        (requestId == null ? 0 : requestId.hashCode) +
        (errors == null ? 0 : errors.hashCode) +
        (currentVersion == null ? 0 : currentVersion.hashCode) +
        (allowed == null ? 0 : allowed.hashCode) +
        (retryAfter == null ? 0 : retryAfter.hashCode);

  factory Problem.fromJson(Map<String, dynamic> json) => _$ProblemFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

