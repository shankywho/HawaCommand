//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/alert_channel.dart';
import 'package:hawa_api/src/model/pollutant.dart';
import 'package:hawa_api/src/model/alert_kind.dart';
import 'package:hawa_api/src/model/alert_status.dart';
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/alert_audience.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alert_item.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlertItem {
  /// Returns a new [AlertItem] instance.
  AlertItem({

    required  this.id,

    required  this.audience,

    required  this.kind,

    required  this.status,

    required  this.lang,

    required  this.title,

    required  this.body,

    required  this.createdAt,

    required  this.isSimulated,

     this.channels,

     this.pollutant,

     this.wardId,

     this.cellId,

     this.planId,

     this.taskId,

     this.reportId,

     this.schoolId,

     this.deepLink,

     this.origin,

     this.args,

     this.sentAt,

     this.readAt,

     this.ackedAt,

     this.expiresAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'audience',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AlertAudience.unknownDefaultOpenApi,
  )


  final AlertAudience audience;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AlertKind.unknownDefaultOpenApi,
  )


  final AlertKind kind;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AlertStatus.unknownDefaultOpenApi,
  )


  final AlertStatus status;



  @JsonKey(
    
    name: r'lang',
    required: true,
    includeIfNull: false,
  unknownEnumValue: Lang.unknownDefaultOpenApi,
  )


  final Lang lang;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'body',
    required: true,
    includeIfNull: false,
  )


  final String body;



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
    
    name: r'channels',
    required: false,
    includeIfNull: false,
  )


  final List<AlertChannel>? channels;



  @JsonKey(
    
    name: r'pollutant',
    required: false,
    includeIfNull: false,
  unknownEnumValue: Pollutant.unknownDefaultOpenApi,
  )


  final Pollutant? pollutant;



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
    
    name: r'plan_id',
    required: false,
    includeIfNull: false,
  )


  final String? planId;



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
    
    name: r'school_id',
    required: false,
    includeIfNull: false,
  )


  final String? schoolId;



  @JsonKey(
    
    name: r'deep_link',
    required: false,
    includeIfNull: false,
  )


  final String? deepLink;



  @JsonKey(
    
    name: r'origin',
    required: false,
    includeIfNull: false,
  )


  final String? origin;



  @JsonKey(
    
    name: r'args',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? args;



  @JsonKey(
    
    name: r'sent_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? sentAt;



  @JsonKey(
    
    name: r'read_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? readAt;



  @JsonKey(
    
    name: r'acked_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? ackedAt;



  @JsonKey(
    
    name: r'expires_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlertItem &&
      other.id == id &&
      other.audience == audience &&
      other.kind == kind &&
      other.status == status &&
      other.lang == lang &&
      other.title == title &&
      other.body == body &&
      other.createdAt == createdAt &&
      other.isSimulated == isSimulated &&
      other.channels == channels &&
      other.pollutant == pollutant &&
      other.wardId == wardId &&
      other.cellId == cellId &&
      other.planId == planId &&
      other.taskId == taskId &&
      other.reportId == reportId &&
      other.schoolId == schoolId &&
      other.deepLink == deepLink &&
      other.origin == origin &&
      other.args == args &&
      other.sentAt == sentAt &&
      other.readAt == readAt &&
      other.ackedAt == ackedAt &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        id.hashCode +
        audience.hashCode +
        kind.hashCode +
        status.hashCode +
        lang.hashCode +
        title.hashCode +
        body.hashCode +
        createdAt.hashCode +
        isSimulated.hashCode +
        (channels == null ? 0 : channels.hashCode) +
        pollutant.hashCode +
        (wardId == null ? 0 : wardId.hashCode) +
        (cellId == null ? 0 : cellId.hashCode) +
        (planId == null ? 0 : planId.hashCode) +
        (taskId == null ? 0 : taskId.hashCode) +
        (reportId == null ? 0 : reportId.hashCode) +
        (schoolId == null ? 0 : schoolId.hashCode) +
        (deepLink == null ? 0 : deepLink.hashCode) +
        (origin == null ? 0 : origin.hashCode) +
        (args == null ? 0 : args.hashCode) +
        (sentAt == null ? 0 : sentAt.hashCode) +
        (readAt == null ? 0 : readAt.hashCode) +
        (ackedAt == null ? 0 : ackedAt.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode);

  factory AlertItem.fromJson(Map<String, dynamic> json) => _$AlertItemFromJson(json);

  Map<String, dynamic> toJson() => _$AlertItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

