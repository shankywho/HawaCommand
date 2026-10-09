//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'school_hours.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolHours {
  /// Returns a new [SchoolHours] instance.
  SchoolHours({

    required  this.dayStart,

    required  this.dayEnd,

     this.assembly,

     this.timezone,
  });

  @JsonKey(
    
    name: r'day_start',
    required: true,
    includeIfNull: false,
  )


  final String dayStart;



  @JsonKey(
    
    name: r'day_end',
    required: true,
    includeIfNull: false,
  )


  final String dayEnd;



  @JsonKey(
    
    name: r'assembly',
    required: false,
    includeIfNull: false,
  )


  final String? assembly;



  @JsonKey(
    
    name: r'timezone',
    required: false,
    includeIfNull: false,
  )


  final String? timezone;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SchoolHours &&
      other.dayStart == dayStart &&
      other.dayEnd == dayEnd &&
      other.assembly == assembly &&
      other.timezone == timezone;

    @override
    int get hashCode =>
        dayStart.hashCode +
        dayEnd.hashCode +
        (assembly == null ? 0 : assembly.hashCode) +
        (timezone == null ? 0 : timezone.hashCode);

  factory SchoolHours.fromJson(Map<String, dynamic> json) => _$SchoolHoursFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolHoursToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

