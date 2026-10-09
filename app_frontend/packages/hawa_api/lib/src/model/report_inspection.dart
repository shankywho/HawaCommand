//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/inspection_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_inspection.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportInspection {
  /// Returns a new [ReportInspection] instance.
  ReportInspection({

    required  this.id,

    required  this.status,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: InspectionStatus.unknownDefaultOpenApi,
  )


  final InspectionStatus status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportInspection &&
      other.id == id &&
      other.status == status;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode;

  factory ReportInspection.fromJson(Map<String, dynamic> json) => _$ReportInspectionFromJson(json);

  Map<String, dynamic> toJson() => _$ReportInspectionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

