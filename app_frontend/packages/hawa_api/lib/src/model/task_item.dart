//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/task_history_entry.dart';
import 'package:hawa_api/src/model/intervention_source.dart';
import 'package:hawa_api/src/model/impact_summary.dart';
import 'package:hawa_api/src/model/task_kind.dart';
import 'package:hawa_api/src/model/task_status.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:hawa_api/src/model/skip_reason.dart';
import 'package:hawa_api/src/model/inspection_origin.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task_item.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TaskItem {
  /// Returns a new [TaskItem] instance.
  TaskItem({

    required  this.id,

    required  this.kind,

    required  this.status,

    required  this.sequence,

    required  this.location,

    required  this.placeName,

    required  this.windowStart,

    required  this.windowEnd,

    required  this.version,

    required  this.updatedAt,

    required  this.isSimulated,

     this.planId,

     this.cellId,

     this.instructions,

     this.targetLitres,

     this.segmentLengthM,

     this.durationMin,

     this.arrivalRadiusM,

     this.causeLabel,

     this.causeConf,

     this.reasonText,

     this.completionSource,

     this.interventionId,

     this.litres,

     this.impactSummary,

     this.skipReason,

     this.inspectionId,

     this.origin,

     this.priority,

     this.hotspotId,

     this.reportId,

     this.siteId,

     this.suspectPin,

     this.history,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  unknownEnumValue: TaskKind.unknownDefaultOpenApi,
  )


  final TaskKind kind;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: TaskStatus.unknownDefaultOpenApi,
  )


  final TaskStatus status;



  @JsonKey(
    
    name: r'sequence',
    required: true,
    includeIfNull: false,
  )


  final int sequence;



  @JsonKey(
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final GeoPoint location;



  @JsonKey(
    
    name: r'place_name',
    required: true,
    includeIfNull: false,
  )


  final LocalizedText placeName;



  @JsonKey(
    
    name: r'window_start',
    required: true,
    includeIfNull: false,
  )


  final DateTime windowStart;



  @JsonKey(
    
    name: r'window_end',
    required: true,
    includeIfNull: false,
  )


  final DateTime windowEnd;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'plan_id',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



  @JsonKey(
    
    name: r'cell_id',
    required: false,
    includeIfNull: false,
  )


  final String? cellId;



  @JsonKey(
    
    name: r'instructions',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? instructions;



  @JsonKey(
    
    name: r'target_litres',
    required: false,
    includeIfNull: false,
  )


  final double? targetLitres;



  @JsonKey(
    
    name: r'segment_length_m',
    required: false,
    includeIfNull: false,
  )


  final double? segmentLengthM;



  @JsonKey(
    
    name: r'duration_min',
    required: false,
    includeIfNull: false,
  )


  final int? durationMin;



  @JsonKey(
    
    name: r'arrival_radius_m',
    required: false,
    includeIfNull: false,
  )


  final double? arrivalRadiusM;



  @JsonKey(
    
    name: r'cause_label',
    required: false,
    includeIfNull: false,
  unknownEnumValue: CauseLabel.unknownDefaultOpenApi,
  )


  final CauseLabel? causeLabel;



  @JsonKey(
    
    name: r'cause_conf',
    required: false,
    includeIfNull: false,
  )


  final double? causeConf;



  @JsonKey(
    
    name: r'reason_text',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? reasonText;



  @JsonKey(
    
    name: r'completion_source',
    required: false,
    includeIfNull: false,
  unknownEnumValue: InterventionSource.unknownDefaultOpenApi,
  )


  final InterventionSource? completionSource;



  @JsonKey(
    
    name: r'intervention_id',
    required: false,
    includeIfNull: false,
  )


  final String? interventionId;



  @JsonKey(
    
    name: r'litres',
    required: false,
    includeIfNull: false,
  )


  final double? litres;



  @JsonKey(
    
    name: r'impact_summary',
    required: false,
    includeIfNull: false,
  )


  final ImpactSummary? impactSummary;



  @JsonKey(
    
    name: r'skip_reason',
    required: false,
    includeIfNull: false,
  unknownEnumValue: SkipReason.unknownDefaultOpenApi,
  )


  final SkipReason? skipReason;



  @JsonKey(
    
    name: r'inspection_id',
    required: false,
    includeIfNull: false,
  )


  final String? inspectionId;



  @JsonKey(
    
    name: r'origin',
    required: false,
    includeIfNull: false,
  unknownEnumValue: InspectionOrigin.unknownDefaultOpenApi,
  )


  final InspectionOrigin? origin;



  @JsonKey(
    
    name: r'priority',
    required: false,
    includeIfNull: false,
  )


  final int? priority;



  @JsonKey(
    
    name: r'hotspot_id',
    required: false,
    includeIfNull: false,
  )


  final String? hotspotId;



  @JsonKey(
    
    name: r'report_id',
    required: false,
    includeIfNull: false,
  )


  final String? reportId;



  @JsonKey(
    
    name: r'site_id',
    required: false,
    includeIfNull: false,
  )


  final String? siteId;



  @JsonKey(
    
    name: r'suspect_pin',
    required: false,
    includeIfNull: false,
  )


  final GeoPoint? suspectPin;



  @JsonKey(
    
    name: r'history',
    required: false,
    includeIfNull: false,
  )


  final List<TaskHistoryEntry>? history;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TaskItem &&
      other.id == id &&
      other.kind == kind &&
      other.status == status &&
      other.sequence == sequence &&
      other.location == location &&
      other.placeName == placeName &&
      other.windowStart == windowStart &&
      other.windowEnd == windowEnd &&
      other.version == version &&
      other.updatedAt == updatedAt &&
      other.isSimulated == isSimulated &&
      other.planId == planId &&
      other.cellId == cellId &&
      other.instructions == instructions &&
      other.targetLitres == targetLitres &&
      other.segmentLengthM == segmentLengthM &&
      other.durationMin == durationMin &&
      other.arrivalRadiusM == arrivalRadiusM &&
      other.causeLabel == causeLabel &&
      other.causeConf == causeConf &&
      other.reasonText == reasonText &&
      other.completionSource == completionSource &&
      other.interventionId == interventionId &&
      other.litres == litres &&
      other.impactSummary == impactSummary &&
      other.skipReason == skipReason &&
      other.inspectionId == inspectionId &&
      other.origin == origin &&
      other.priority == priority &&
      other.hotspotId == hotspotId &&
      other.reportId == reportId &&
      other.siteId == siteId &&
      other.suspectPin == suspectPin &&
      other.history == history;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        status.hashCode +
        sequence.hashCode +
        location.hashCode +
        placeName.hashCode +
        windowStart.hashCode +
        windowEnd.hashCode +
        version.hashCode +
        updatedAt.hashCode +
        isSimulated.hashCode +
        (planId == null ? 0 : planId.hashCode) +
        (cellId == null ? 0 : cellId.hashCode) +
        instructions.hashCode +
        (targetLitres == null ? 0 : targetLitres.hashCode) +
        (segmentLengthM == null ? 0 : segmentLengthM.hashCode) +
        (durationMin == null ? 0 : durationMin.hashCode) +
        (arrivalRadiusM == null ? 0 : arrivalRadiusM.hashCode) +
        causeLabel.hashCode +
        (causeConf == null ? 0 : causeConf.hashCode) +
        reasonText.hashCode +
        completionSource.hashCode +
        (interventionId == null ? 0 : interventionId.hashCode) +
        (litres == null ? 0 : litres.hashCode) +
        impactSummary.hashCode +
        skipReason.hashCode +
        (inspectionId == null ? 0 : inspectionId.hashCode) +
        origin.hashCode +
        (priority == null ? 0 : priority.hashCode) +
        (hotspotId == null ? 0 : hotspotId.hashCode) +
        (reportId == null ? 0 : reportId.hashCode) +
        (siteId == null ? 0 : siteId.hashCode) +
        suspectPin.hashCode +
        (history == null ? 0 : history.hashCode);

  factory TaskItem.fromJson(Map<String, dynamic> json) => _$TaskItemFromJson(json);

  Map<String, dynamic> toJson() => _$TaskItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

