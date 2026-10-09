//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/report_timeline_entry.dart';
import 'package:hawa_api/src/model/report_verification.dart';
import 'package:hawa_api/src/model/report_category.dart';
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/report_inspection.dart';
import 'package:hawa_api/src/model/report_source.dart';
import 'package:hawa_api/src/model/inspection_outcome.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:hawa_api/src/model/report_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_detail_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportDetailOut {
  /// Returns a new [ReportDetailOut] instance.
  ReportDetailOut({

    required  this.id,

    required  this.status,

    required  this.location,

    required  this.createdAt,

    required  this.timeline,

    required  this.isSimulated,

     this.clientReportId,

     this.source_,

     this.accuracyM,

     this.wardId,

     this.cellId,

     this.placeName,

     this.note,

     this.lang,

     this.category,

     this.capturedAt,

     this.photoUrl,

     this.verification,

     this.inspection,

     this.outcome,

     this.outcomeText,

     this.outcomeTextHi,

     this.rejectionReason,

     this.rejectionReasonHi,

     this.closedAt,
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
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final GeoPoint location;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'timeline',
    required: true,
    includeIfNull: false,
  )


  final List<ReportTimelineEntry> timeline;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'client_report_id',
    required: false,
    includeIfNull: false,
  )


  final String? clientReportId;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  unknownEnumValue: ReportSource.unknownDefaultOpenApi,
  )


  final ReportSource? source_;



  @JsonKey(
    
    name: r'accuracy_m',
    required: false,
    includeIfNull: false,
  )


  final double? accuracyM;



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



  @JsonKey(
    
    name: r'place_name',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? placeName;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;



  @JsonKey(
    
    name: r'lang',
    required: false,
    includeIfNull: false,
  unknownEnumValue: Lang.unknownDefaultOpenApi,
  )


  final Lang? lang;



  @JsonKey(
    
    name: r'category',
    required: false,
    includeIfNull: false,
  unknownEnumValue: ReportCategory.unknownDefaultOpenApi,
  )


  final ReportCategory? category;



  @JsonKey(
    
    name: r'captured_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? capturedAt;



  @JsonKey(
    
    name: r'photo_url',
    required: false,
    includeIfNull: false,
  )


  final String? photoUrl;



  @JsonKey(
    
    name: r'verification',
    required: false,
    includeIfNull: false,
  )


  final ReportVerification? verification;



  @JsonKey(
    
    name: r'inspection',
    required: false,
    includeIfNull: false,
  )


  final ReportInspection? inspection;



  @JsonKey(
    
    name: r'outcome',
    required: false,
    includeIfNull: false,
  unknownEnumValue: InspectionOutcome.unknownDefaultOpenApi,
  )


  final InspectionOutcome? outcome;



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
    
    name: r'rejection_reason',
    required: false,
    includeIfNull: false,
  )


  final String? rejectionReason;



  @JsonKey(
    
    name: r'rejection_reason_hi',
    required: false,
    includeIfNull: false,
  )


  final String? rejectionReasonHi;



  @JsonKey(
    
    name: r'closed_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? closedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportDetailOut &&
      other.id == id &&
      other.status == status &&
      other.location == location &&
      other.createdAt == createdAt &&
      other.timeline == timeline &&
      other.isSimulated == isSimulated &&
      other.clientReportId == clientReportId &&
      other.source_ == source_ &&
      other.accuracyM == accuracyM &&
      other.wardId == wardId &&
      other.cellId == cellId &&
      other.placeName == placeName &&
      other.note == note &&
      other.lang == lang &&
      other.category == category &&
      other.capturedAt == capturedAt &&
      other.photoUrl == photoUrl &&
      other.verification == verification &&
      other.inspection == inspection &&
      other.outcome == outcome &&
      other.outcomeText == outcomeText &&
      other.outcomeTextHi == outcomeTextHi &&
      other.rejectionReason == rejectionReason &&
      other.rejectionReasonHi == rejectionReasonHi &&
      other.closedAt == closedAt;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode +
        location.hashCode +
        createdAt.hashCode +
        timeline.hashCode +
        isSimulated.hashCode +
        (clientReportId == null ? 0 : clientReportId.hashCode) +
        source_.hashCode +
        (accuracyM == null ? 0 : accuracyM.hashCode) +
        (wardId == null ? 0 : wardId.hashCode) +
        (cellId == null ? 0 : cellId.hashCode) +
        placeName.hashCode +
        (note == null ? 0 : note.hashCode) +
        lang.hashCode +
        category.hashCode +
        (capturedAt == null ? 0 : capturedAt.hashCode) +
        (photoUrl == null ? 0 : photoUrl.hashCode) +
        verification.hashCode +
        inspection.hashCode +
        outcome.hashCode +
        (outcomeText == null ? 0 : outcomeText.hashCode) +
        (outcomeTextHi == null ? 0 : outcomeTextHi.hashCode) +
        (rejectionReason == null ? 0 : rejectionReason.hashCode) +
        (rejectionReasonHi == null ? 0 : rejectionReasonHi.hashCode) +
        (closedAt == null ? 0 : closedAt.hashCode);

  factory ReportDetailOut.fromJson(Map<String, dynamic> json) => _$ReportDetailOutFromJson(json);

  Map<String, dynamic> toJson() => _$ReportDetailOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

