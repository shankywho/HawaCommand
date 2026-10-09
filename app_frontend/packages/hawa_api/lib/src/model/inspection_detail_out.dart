//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/spike_evidence.dart';
import 'package:hawa_api/src/model/reporter.dart';
import 'package:hawa_api/src/model/evidence_photo.dart';
import 'package:hawa_api/src/model/inspection_status.dart';
import 'package:hawa_api/src/model/geo_line_string.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:hawa_api/src/model/inspection_origin.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_detail_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InspectionDetailOut {
  /// Returns a new [InspectionDetailOut] instance.
  InspectionDetailOut({

    required  this.id,

    required  this.status,

    required  this.origin,

    required  this.priority,

    required  this.causeLabel,

    required  this.causeConf,

    required  this.suspectPin,

    required  this.photos,

    required  this.isSimulated,

     this.taskId,

     this.reportId,

     this.hotspotId,

     this.siteId,

     this.placeName,

     this.suspectRadiusM,

     this.backTrajectory,

     this.spike,

     this.reporter,

     this.createdAt,

     this.reportedAt,
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



  @JsonKey(
    
    name: r'origin',
    required: true,
    includeIfNull: false,
  unknownEnumValue: InspectionOrigin.unknownDefaultOpenApi,
  )


  final InspectionOrigin origin;



  @JsonKey(
    
    name: r'priority',
    required: true,
    includeIfNull: false,
  )


  final int priority;



  @JsonKey(
    
    name: r'cause_label',
    required: true,
    includeIfNull: false,
  unknownEnumValue: CauseLabel.unknownDefaultOpenApi,
  )


  final CauseLabel causeLabel;



  @JsonKey(
    
    name: r'cause_conf',
    required: true,
    includeIfNull: false,
  )


  final double causeConf;



  @JsonKey(
    
    name: r'suspect_pin',
    required: true,
    includeIfNull: false,
  )


  final GeoPoint suspectPin;



  @JsonKey(
    
    name: r'photos',
    required: true,
    includeIfNull: false,
  )


  final List<EvidencePhoto> photos;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'task_id',
    required: false,
    includeIfNull: false,
  )


  final String? taskId;



  @JsonKey(
    
    name: r'report_id',
    required: false,
    includeIfNull: false,
  )


  final String? reportId;



  @JsonKey(
    
    name: r'hotspot_id',
    required: false,
    includeIfNull: false,
  )


  final String? hotspotId;



  @JsonKey(
    
    name: r'site_id',
    required: false,
    includeIfNull: false,
  )


  final String? siteId;



  @JsonKey(
    
    name: r'place_name',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? placeName;



  @JsonKey(
    
    name: r'suspect_radius_m',
    required: false,
    includeIfNull: false,
  )


  final double? suspectRadiusM;



  @JsonKey(
    
    name: r'back_trajectory',
    required: false,
    includeIfNull: false,
  )


  final GeoLineString? backTrajectory;



  @JsonKey(
    
    name: r'spike',
    required: false,
    includeIfNull: false,
  )


  final SpikeEvidence? spike;



  @JsonKey(
    
    name: r'reporter',
    required: false,
    includeIfNull: false,
  )


  final Reporter? reporter;



  @JsonKey(
    
    name: r'created_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? createdAt;



  @JsonKey(
    
    name: r'reported_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? reportedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InspectionDetailOut &&
      other.id == id &&
      other.status == status &&
      other.origin == origin &&
      other.priority == priority &&
      other.causeLabel == causeLabel &&
      other.causeConf == causeConf &&
      other.suspectPin == suspectPin &&
      other.photos == photos &&
      other.isSimulated == isSimulated &&
      other.taskId == taskId &&
      other.reportId == reportId &&
      other.hotspotId == hotspotId &&
      other.siteId == siteId &&
      other.placeName == placeName &&
      other.suspectRadiusM == suspectRadiusM &&
      other.backTrajectory == backTrajectory &&
      other.spike == spike &&
      other.reporter == reporter &&
      other.createdAt == createdAt &&
      other.reportedAt == reportedAt;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode +
        origin.hashCode +
        priority.hashCode +
        causeLabel.hashCode +
        causeConf.hashCode +
        suspectPin.hashCode +
        photos.hashCode +
        isSimulated.hashCode +
        (taskId == null ? 0 : taskId.hashCode) +
        (reportId == null ? 0 : reportId.hashCode) +
        (hotspotId == null ? 0 : hotspotId.hashCode) +
        (siteId == null ? 0 : siteId.hashCode) +
        placeName.hashCode +
        (suspectRadiusM == null ? 0 : suspectRadiusM.hashCode) +
        backTrajectory.hashCode +
        spike.hashCode +
        reporter.hashCode +
        (createdAt == null ? 0 : createdAt.hashCode) +
        (reportedAt == null ? 0 : reportedAt.hashCode);

  factory InspectionDetailOut.fromJson(Map<String, dynamic> json) => _$InspectionDetailOutFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionDetailOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

