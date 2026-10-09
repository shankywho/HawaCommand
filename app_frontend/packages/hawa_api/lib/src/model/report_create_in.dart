//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/report_category.dart';
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_create_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportCreateIn {
  /// Returns a new [ReportCreateIn] instance.
  ReportCreateIn({

    required  this.clientReportId,

    required  this.photoKey,

    required  this.location,

    required  this.capturedAt,

     this.accuracyM,

     this.note,

     this.lang,

     this.category,
  });

  @JsonKey(
    
    name: r'client_report_id',
    required: true,
    includeIfNull: false,
  )


  final String clientReportId;



  @JsonKey(
    
    name: r'photo_key',
    required: true,
    includeIfNull: false,
  )


  final String photoKey;



  @JsonKey(
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final GeoPoint location;



  @JsonKey(
    
    name: r'captured_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime capturedAt;



  @JsonKey(
    
    name: r'accuracy_m',
    required: false,
    includeIfNull: false,
  )


  final double? accuracyM;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportCreateIn &&
      other.clientReportId == clientReportId &&
      other.photoKey == photoKey &&
      other.location == location &&
      other.capturedAt == capturedAt &&
      other.accuracyM == accuracyM &&
      other.note == note &&
      other.lang == lang &&
      other.category == category;

    @override
    int get hashCode =>
        clientReportId.hashCode +
        photoKey.hashCode +
        location.hashCode +
        capturedAt.hashCode +
        (accuracyM == null ? 0 : accuracyM.hashCode) +
        (note == null ? 0 : note.hashCode) +
        lang.hashCode +
        category.hashCode;

  factory ReportCreateIn.fromJson(Map<String, dynamic> json) => _$ReportCreateInFromJson(json);

  Map<String, dynamic> toJson() => _$ReportCreateInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

