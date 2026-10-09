//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/classroom_advice.dart';
import 'package:hawa_api/src/model/indoor_outdoor_summary.dart';
import 'package:hawa_api/src/model/indoor_outdoor_point.dart';
import 'package:hawa_api/src/model/indoor_outdoor_devices.dart';
import 'package:json_annotation/json_annotation.dart';

part 'indoor_outdoor_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IndoorOutdoorOut {
  /// Returns a new [IndoorOutdoorOut] instance.
  IndoorOutdoorOut({

    required  this.schoolId,

    required  this.interval,

    required  this.series,

    required  this.isSimulated,

     this.summary,

     this.devices,

     this.advice,

     this.adviceReason,

     this.adviceReasonHi,
  });

  @JsonKey(
    
    name: r'school_id',
    required: true,
    includeIfNull: false,
  )


  final String schoolId;



  @JsonKey(
    
    name: r'interval',
    required: true,
    includeIfNull: false,
  )


  final String interval;



  @JsonKey(
    
    name: r'series',
    required: true,
    includeIfNull: false,
  )


  final List<IndoorOutdoorPoint> series;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'summary',
    required: false,
    includeIfNull: false,
  )


  final IndoorOutdoorSummary? summary;



  @JsonKey(
    
    name: r'devices',
    required: false,
    includeIfNull: false,
  )


  final IndoorOutdoorDevices? devices;



  @JsonKey(
    
    name: r'advice',
    required: false,
    includeIfNull: false,
  unknownEnumValue: ClassroomAdvice.unknownDefaultOpenApi,
  )


  final ClassroomAdvice? advice;



  @JsonKey(
    
    name: r'advice_reason',
    required: false,
    includeIfNull: false,
  )


  final String? adviceReason;



  @JsonKey(
    
    name: r'advice_reason_hi',
    required: false,
    includeIfNull: false,
  )


  final String? adviceReasonHi;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IndoorOutdoorOut &&
      other.schoolId == schoolId &&
      other.interval == interval &&
      other.series == series &&
      other.isSimulated == isSimulated &&
      other.summary == summary &&
      other.devices == devices &&
      other.advice == advice &&
      other.adviceReason == adviceReason &&
      other.adviceReasonHi == adviceReasonHi;

    @override
    int get hashCode =>
        schoolId.hashCode +
        interval.hashCode +
        series.hashCode +
        isSimulated.hashCode +
        summary.hashCode +
        devices.hashCode +
        advice.hashCode +
        (adviceReason == null ? 0 : adviceReason.hashCode) +
        (adviceReasonHi == null ? 0 : adviceReasonHi.hashCode);

  factory IndoorOutdoorOut.fromJson(Map<String, dynamic> json) => _$IndoorOutdoorOutFromJson(json);

  Map<String, dynamic> toJson() => _$IndoorOutdoorOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

