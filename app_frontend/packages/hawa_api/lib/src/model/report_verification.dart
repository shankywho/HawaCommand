//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_verification.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportVerification {
  /// Returns a new [ReportVerification] instance.
  ReportVerification({

    required  this.verified,

     this.label,

     this.confidence,

     this.verifiedAt,

     this.modelVersion,
  });

  @JsonKey(
    
    name: r'verified',
    required: true,
    includeIfNull: false,
  )


  final bool verified;



  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  unknownEnumValue: CauseLabel.unknownDefaultOpenApi,
  )


  final CauseLabel? label;



  @JsonKey(
    
    name: r'confidence',
    required: false,
    includeIfNull: false,
  )


  final double? confidence;



  @JsonKey(
    
    name: r'verified_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? verifiedAt;



  @JsonKey(
    
    name: r'model_version',
    required: false,
    includeIfNull: false,
  )


  final String? modelVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportVerification &&
      other.verified == verified &&
      other.label == label &&
      other.confidence == confidence &&
      other.verifiedAt == verifiedAt &&
      other.modelVersion == modelVersion;

    @override
    int get hashCode =>
        verified.hashCode +
        label.hashCode +
        (confidence == null ? 0 : confidence.hashCode) +
        (verifiedAt == null ? 0 : verifiedAt.hashCode) +
        (modelVersion == null ? 0 : modelVersion.hashCode);

  factory ReportVerification.fromJson(Map<String, dynamic> json) => _$ReportVerificationFromJson(json);

  Map<String, dynamic> toJson() => _$ReportVerificationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

