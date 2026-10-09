//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/site_grade.dart';
import 'package:hawa_api/src/model/pm10_trend_point.dart';
import 'package:hawa_api/src/model/site_score_component.dart';
import 'package:hawa_api/src/model/site_type.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_me_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteMeOut {
  /// Returns a new [SiteMeOut] instance.
  SiteMeOut({

    required  this.siteId,

    required  this.type,

    required  this.name,

    required  this.grade,

    required  this.isSimulated,

     this.wardId,

     this.placeName,

     this.gradeSince,

     this.score,

     this.violations,

     this.flags30d,

     this.lastInspectionAt,

     this.pm10Trend,

     this.components,

     this.tips,
  });

  @JsonKey(
    
    name: r'site_id',
    required: true,
    includeIfNull: false,
  )


  final String siteId;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  unknownEnumValue: SiteType.unknownDefaultOpenApi,
  )


  final SiteType type;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'grade',
    required: true,
    includeIfNull: false,
  unknownEnumValue: SiteGrade.unknownDefaultOpenApi,
  )


  final SiteGrade grade;



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
    
    name: r'place_name',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? placeName;



  @JsonKey(
    
    name: r'grade_since',
    required: false,
    includeIfNull: false,
  )


  final DateTime? gradeSince;



  @JsonKey(
    
    name: r'score',
    required: false,
    includeIfNull: false,
  )


  final double? score;



  @JsonKey(
    
    name: r'violations',
    required: false,
    includeIfNull: false,
  )


  final int? violations;



  @JsonKey(
    
    name: r'flags_30d',
    required: false,
    includeIfNull: false,
  )


  final int? flags30d;



  @JsonKey(
    
    name: r'last_inspection_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? lastInspectionAt;



  @JsonKey(
    
    name: r'pm10_trend',
    required: false,
    includeIfNull: false,
  )


  final List<Pm10TrendPoint>? pm10Trend;



  @JsonKey(
    
    name: r'components',
    required: false,
    includeIfNull: false,
  )


  final List<SiteScoreComponent>? components;



  @JsonKey(
    
    name: r'tips',
    required: false,
    includeIfNull: false,
  )


  final List<LocalizedText>? tips;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteMeOut &&
      other.siteId == siteId &&
      other.type == type &&
      other.name == name &&
      other.grade == grade &&
      other.isSimulated == isSimulated &&
      other.wardId == wardId &&
      other.placeName == placeName &&
      other.gradeSince == gradeSince &&
      other.score == score &&
      other.violations == violations &&
      other.flags30d == flags30d &&
      other.lastInspectionAt == lastInspectionAt &&
      other.pm10Trend == pm10Trend &&
      other.components == components &&
      other.tips == tips;

    @override
    int get hashCode =>
        siteId.hashCode +
        type.hashCode +
        name.hashCode +
        grade.hashCode +
        isSimulated.hashCode +
        (wardId == null ? 0 : wardId.hashCode) +
        placeName.hashCode +
        (gradeSince == null ? 0 : gradeSince.hashCode) +
        (score == null ? 0 : score.hashCode) +
        (violations == null ? 0 : violations.hashCode) +
        (flags30d == null ? 0 : flags30d.hashCode) +
        (lastInspectionAt == null ? 0 : lastInspectionAt.hashCode) +
        (pm10Trend == null ? 0 : pm10Trend.hashCode) +
        (components == null ? 0 : components.hashCode) +
        (tips == null ? 0 : tips.hashCode);

  factory SiteMeOut.fromJson(Map<String, dynamic> json) => _$SiteMeOutFromJson(json);

  Map<String, dynamic> toJson() => _$SiteMeOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

