//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/report_source.dart';
import 'package:hawa_api/src/model/inspection_status.dart';
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:hawa_api/src/model/report_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_list_item.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportListItem {
  /// Returns a new [ReportListItem] instance.
  ReportListItem({

    required  this.id,

    required  this.status,

    required  this.createdAt,

     this.clientReportId,

     this.wardId,

     this.note,

     this.thumbnailUrl,

     this.placeName,

     this.verificationLabel,

     this.inspectionStatus,

     this.outcomeText,

     this.outcomeTextHi,

     this.closedAt,

     this.source_,

     this.isSimulated,
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
  unknownEnumValue: ReportStatus.unknownDefaultOpenApi,
  )


  final ReportStatus status;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



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
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;



  @JsonKey(
    
    name: r'thumbnail_url',
    required: false,
    includeIfNull: false,
  )


  final String? thumbnailUrl;



  @JsonKey(
    
    name: r'place_name',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? placeName;



  @JsonKey(
    
    name: r'verification_label',
    required: false,
    includeIfNull: false,
  unknownEnumValue: CauseLabel.unknownDefaultOpenApi,
  )


  final CauseLabel? verificationLabel;



  @JsonKey(
    
    name: r'inspection_status',
    required: false,
    includeIfNull: false,
  unknownEnumValue: InspectionStatus.unknownDefaultOpenApi,
  )


  final InspectionStatus? inspectionStatus;



  @JsonKey(
    
    name: r'outcome_text',
    required: false,
    includeIfNull: false,
  )


  final String? outcomeText;



  @JsonKey(
    
    name: r'outcome_text_hi',
    required: false,
    includeIfNull: false,
  )


  final String? outcomeTextHi;



  @JsonKey(
    
    name: r'closed_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? closedAt;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  unknownEnumValue: ReportSource.unknownDefaultOpenApi,
  )


  final ReportSource? source_;



  @JsonKey(
    
    name: r'is_simulated',
    required: false,
    includeIfNull: false,
  )


  final bool? isSimulated;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportListItem &&
      other.id == id &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.clientReportId == clientReportId &&
      other.wardId == wardId &&
      other.note == note &&
      other.thumbnailUrl == thumbnailUrl &&
      other.placeName == placeName &&
      other.verificationLabel == verificationLabel &&
      other.inspectionStatus == inspectionStatus &&
      other.outcomeText == outcomeText &&
      other.outcomeTextHi == outcomeTextHi &&
      other.closedAt == closedAt &&
      other.source_ == source_ &&
      other.isSimulated == isSimulated;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode +
        createdAt.hashCode +
        (clientReportId == null ? 0 : clientReportId.hashCode) +
        (wardId == null ? 0 : wardId.hashCode) +
        (note == null ? 0 : note.hashCode) +
        (thumbnailUrl == null ? 0 : thumbnailUrl.hashCode) +
        placeName.hashCode +
        verificationLabel.hashCode +
        inspectionStatus.hashCode +
        (outcomeText == null ? 0 : outcomeText.hashCode) +
        (outcomeTextHi == null ? 0 : outcomeTextHi.hashCode) +
        (closedAt == null ? 0 : closedAt.hashCode) +
        source_.hashCode +
        (isSimulated == null ? 0 : isSimulated.hashCode);

  factory ReportListItem.fromJson(Map<String, dynamic> json) => _$ReportListItemFromJson(json);

  Map<String, dynamic> toJson() => _$ReportListItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

