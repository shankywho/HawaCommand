//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/report_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_create_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportCreateOut {
  /// Returns a new [ReportCreateOut] instance.
  ReportCreateOut({

    required  this.reportId,

    required  this.status,

     this.clientReportId,

     this.wardId,

     this.cellId,
  });

  @JsonKey(
    
    name: r'report_id',
    required: true,
    includeIfNull: false,
  )


  final String reportId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ReportStatus.unknownDefaultOpenApi,
  )


  final ReportStatus status;



  @JsonKey(
    
    name: r'client_report_id',
    required: false,
    includeIfNull: false,
  )


  final String? clientReportId;



  @JsonKey(
    
    name: r'ward_id',
    required: false,
    includeIfNull: false,
  )


  final String? wardId;



  @JsonKey(
    
    name: r'cell_id',
    required: false,
    includeIfNull: false,
  )


  final String? cellId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportCreateOut &&
      other.reportId == reportId &&
      other.status == status &&
      other.clientReportId == clientReportId &&
      other.wardId == wardId &&
      other.cellId == cellId;

    @override
    int get hashCode =>
        reportId.hashCode +
        status.hashCode +
        (clientReportId == null ? 0 : clientReportId.hashCode) +
        (wardId == null ? 0 : wardId.hashCode) +
        (cellId == null ? 0 : cellId.hashCode);

  factory ReportCreateOut.fromJson(Map<String, dynamic> json) => _$ReportCreateOutFromJson(json);

  Map<String, dynamic> toJson() => _$ReportCreateOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

