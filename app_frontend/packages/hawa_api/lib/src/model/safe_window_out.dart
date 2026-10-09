//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/classroom_advice.dart';
import 'package:hawa_api/src/model/quantile_value.dart';
import 'package:hawa_api/src/model/safe_window.dart';
import 'package:json_annotation/json_annotation.dart';

part 'safe_window_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SafeWindowOut {
  /// Returns a new [SafeWindowOut] instance.
  SafeWindowOut({

    required  this.schoolId,

    required  this.date,

    required  this.issuedAt,

    required  this.isFinal,

    required  this.windows,

    required  this.advice,

    required  this.isSimulated,

     this.adviceReason,

     this.adviceReasonHi,

     this.assemblyPm25,

     this.alertRequired,

     this.modelVersion,
  });

  @JsonKey(
    
    name: r'school_id',
    required: true,
    includeIfNull: false,
  )


  final String schoolId;



  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final DateTime date;



  @JsonKey(
    
    name: r'issued_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime issuedAt;



  @JsonKey(
    
    name: r'is_final',
    required: true,
    includeIfNull: false,
  )


  final bool isFinal;



  @JsonKey(
    
    name: r'windows',
    required: true,
    includeIfNull: false,
  )


  final List<SafeWindow> windows;



  @JsonKey(
    
    name: r'advice',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ClassroomAdvice.unknownDefaultOpenApi,
  )


  final ClassroomAdvice advice;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



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



  @JsonKey(
    
    name: r'assembly_pm25',
    required: false,
    includeIfNull: false,
  )


  final QuantileValue? assemblyPm25;



  @JsonKey(
    
    name: r'alert_required',
    required: false,
    includeIfNull: false,
  )


  final bool? alertRequired;



  @JsonKey(
    
    name: r'model_version',
    required: false,
    includeIfNull: false,
  )


  final String? modelVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SafeWindowOut &&
      other.schoolId == schoolId &&
      other.date == date &&
      other.issuedAt == issuedAt &&
      other.isFinal == isFinal &&
      other.windows == windows &&
      other.advice == advice &&
      other.isSimulated == isSimulated &&
      other.adviceReason == adviceReason &&
      other.adviceReasonHi == adviceReasonHi &&
      other.assemblyPm25 == assemblyPm25 &&
      other.alertRequired == alertRequired &&
      other.modelVersion == modelVersion;

    @override
    int get hashCode =>
        schoolId.hashCode +
        date.hashCode +
        issuedAt.hashCode +
        isFinal.hashCode +
        windows.hashCode +
        advice.hashCode +
        isSimulated.hashCode +
        (adviceReason == null ? 0 : adviceReason.hashCode) +
        (adviceReasonHi == null ? 0 : adviceReasonHi.hashCode) +
        assemblyPm25.hashCode +
        (alertRequired == null ? 0 : alertRequired.hashCode) +
        (modelVersion == null ? 0 : modelVersion.hashCode);

  factory SafeWindowOut.fromJson(Map<String, dynamic> json) => _$SafeWindowOutFromJson(json);

  Map<String, dynamic> toJson() => _$SafeWindowOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

