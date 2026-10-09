//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/classroom_advice.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school_now.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolNow {
  /// Returns a new [SchoolNow] instance.
  SchoolNow({

    required  this.ts,

     this.outdoorPm25,

     this.indoorPm25,

     this.indoorCo2Ppm,

     this.ratioInOut,

     this.advice,
  });

  @JsonKey(
    
    name: r'ts',
    required: true,
    includeIfNull: false,
  )


  final DateTime ts;



  @JsonKey(
    
    name: r'outdoor_pm25',
    required: false,
    includeIfNull: false,
  )


  final double? outdoorPm25;



  @JsonKey(
    
    name: r'indoor_pm25',
    required: false,
    includeIfNull: false,
  )


  final double? indoorPm25;



  @JsonKey(
    
    name: r'indoor_co2_ppm',
    required: false,
    includeIfNull: false,
  )


  final double? indoorCo2Ppm;



  @JsonKey(
    
    name: r'ratio_in_out',
    required: false,
    includeIfNull: false,
  )


  final double? ratioInOut;



  @JsonKey(
    
    name: r'advice',
    required: false,
    includeIfNull: false,
  unknownEnumValue: ClassroomAdvice.unknownDefaultOpenApi,
  )


  final ClassroomAdvice? advice;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SchoolNow &&
      other.ts == ts &&
      other.outdoorPm25 == outdoorPm25 &&
      other.indoorPm25 == indoorPm25 &&
      other.indoorCo2Ppm == indoorCo2Ppm &&
      other.ratioInOut == ratioInOut &&
      other.advice == advice;

    @override
    int get hashCode =>
        ts.hashCode +
        (outdoorPm25 == null ? 0 : outdoorPm25.hashCode) +
        (indoorPm25 == null ? 0 : indoorPm25.hashCode) +
        (indoorCo2Ppm == null ? 0 : indoorCo2Ppm.hashCode) +
        (ratioInOut == null ? 0 : ratioInOut.hashCode) +
        advice.hashCode;

  factory SchoolNow.fromJson(Map<String, dynamic> json) => _$SchoolNowFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolNowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

