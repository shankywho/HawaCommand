//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/evidence_summary.dart';
import 'package:hawa_api/src/model/inspection_status.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:hawa_api/src/model/inspection_origin.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_list_item.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InspectionListItem {
  /// Returns a new [InspectionListItem] instance.
  InspectionListItem({

    required  this.id,

    required  this.status,

    required  this.origin,

    required  this.priority,

    required  this.target,

    required  this.createdAt,

    required  this.isSimulated,

     this.wardId,

     this.cellId,

     this.reportId,

     this.hotspotId,

     this.taskId,

     this.siteId,

     this.placeName,

     this.causeLabel,

     this.causeConf,

     this.evidenceSummary,

     this.assignedTeamAssetId,
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
    
    name: r'target',
    required: true,
    includeIfNull: false,
  )


  final GeoPoint target;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



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
    
    name: r'task_id',
    required: false,
    includeIfNull: false,
  )


  final String? taskId;



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
    
    name: r'evidence_summary',
    required: false,
    includeIfNull: false,
  )


  final EvidenceSummary? evidenceSummary;



  @JsonKey(
    
    name: r'assigned_team_asset_id',
    required: false,
    includeIfNull: false,
  )


  final String? assignedTeamAssetId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InspectionListItem &&
      other.id == id &&
      other.status == status &&
      other.origin == origin &&
      other.priority == priority &&
      other.target == target &&
      other.createdAt == createdAt &&
      other.isSimulated == isSimulated &&
      other.wardId == wardId &&
      other.cellId == cellId &&
      other.reportId == reportId &&
      other.hotspotId == hotspotId &&
      other.taskId == taskId &&
      other.siteId == siteId &&
      other.placeName == placeName &&
      other.causeLabel == causeLabel &&
      other.causeConf == causeConf &&
      other.evidenceSummary == evidenceSummary &&
      other.assignedTeamAssetId == assignedTeamAssetId;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode +
        origin.hashCode +
        priority.hashCode +
        target.hashCode +
        createdAt.hashCode +
        isSimulated.hashCode +
        (wardId == null ? 0 : wardId.hashCode) +
        (cellId == null ? 0 : cellId.hashCode) +
        (reportId == null ? 0 : reportId.hashCode) +
        (hotspotId == null ? 0 : hotspotId.hashCode) +
        (taskId == null ? 0 : taskId.hashCode) +
        (siteId == null ? 0 : siteId.hashCode) +
        placeName.hashCode +
        causeLabel.hashCode +
        (causeConf == null ? 0 : causeConf.hashCode) +
        evidenceSummary.hashCode +
        (assignedTeamAssetId == null ? 0 : assignedTeamAssetId.hashCode);

  factory InspectionListItem.fromJson(Map<String, dynamic> json) => _$InspectionListItemFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionListItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

