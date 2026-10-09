//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/classroom_advice.dart';
import 'package:hawa_api/src/model/safe_window.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school_today.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolToday {
  /// Returns a new [SchoolToday] instance.
  SchoolToday({

    required  this.date,

     this.advice,

     this.safeWindows,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final DateTime date;



  @JsonKey(
    
    name: r'advice',
    required: false,
    includeIfNull: false,
  unknownEnumValue: ClassroomAdvice.unknownDefaultOpenApi,
  )


  final ClassroomAdvice? advice;



  @JsonKey(
    
    name: r'safe_windows',
    required: false,
    includeIfNull: false,
  )


  final List<SafeWindow>? safeWindows;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SchoolToday &&
      other.date == date &&
      other.advice == advice &&
      other.safeWindows == safeWindows;

    @override
    int get hashCode =>
        date.hashCode +
        advice.hashCode +
        (safeWindows == null ? 0 : safeWindows.hashCode);

  factory SchoolToday.fromJson(Map<String, dynamic> json) => _$SchoolTodayFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolTodayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

