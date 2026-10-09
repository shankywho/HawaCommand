//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'problem_field_error.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProblemFieldError {
  /// Returns a new [ProblemFieldError] instance.
  ProblemFieldError({

    required  this.pointer,

    required  this.code,

     this.detail,
  });

  @JsonKey(
    
    name: r'pointer',
    required: true,
    includeIfNull: false,
  )


  final String pointer;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProblemFieldError &&
      other.pointer == pointer &&
      other.code == code &&
      other.detail == detail;

    @override
    int get hashCode =>
        pointer.hashCode +
        code.hashCode +
        (detail == null ? 0 : detail.hashCode);

  factory ProblemFieldError.fromJson(Map<String, dynamic> json) => _$ProblemFieldErrorFromJson(json);

  Map<String, dynamic> toJson() => _$ProblemFieldErrorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

