//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'forecast_point.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForecastPoint {
  /// Returns a new [ForecastPoint] instance.
  ForecastPoint({

    required  this.horizonH,

    required  this.validAt,

    required  this.p50,

     this.p10,

     this.p90,

     this.aqiP50,

     this.grapStage,

     this.pStageUp,
  });

  @JsonKey(
    
    name: r'horizon_h',
    required: true,
    includeIfNull: false,
  )


  final int horizonH;



  @JsonKey(
    
    name: r'valid_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime validAt;



  @JsonKey(
    
    name: r'p50',
    required: true,
    includeIfNull: false,
  )


  final double p50;



  @JsonKey(
    
    name: r'p10',
    required: false,
    includeIfNull: false,
  )


  final double? p10;



  @JsonKey(
    
    name: r'p90',
    required: false,
    includeIfNull: false,
  )


  final double? p90;



  @JsonKey(
    
    name: r'aqi_p50',
    required: false,
    includeIfNull: false,
  )


  final int? aqiP50;



  @JsonKey(
    
    name: r'grap_stage',
    required: false,
    includeIfNull: false,
  )


  final int? grapStage;



  @JsonKey(
    
    name: r'p_stage_up',
    required: false,
    includeIfNull: false,
  )


  final double? pStageUp;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ForecastPoint &&
      other.horizonH == horizonH &&
      other.validAt == validAt &&
      other.p50 == p50 &&
      other.p10 == p10 &&
      other.p90 == p90 &&
      other.aqiP50 == aqiP50 &&
      other.grapStage == grapStage &&
      other.pStageUp == pStageUp;

    @override
    int get hashCode =>
        horizonH.hashCode +
        validAt.hashCode +
        p50.hashCode +
        (p10 == null ? 0 : p10.hashCode) +
        (p90 == null ? 0 : p90.hashCode) +
        (aqiP50 == null ? 0 : aqiP50.hashCode) +
        (grapStage == null ? 0 : grapStage.hashCode) +
        (pStageUp == null ? 0 : pStageUp.hashCode);

  factory ForecastPoint.fromJson(Map<String, dynamic> json) => _$ForecastPointFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastPointToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

