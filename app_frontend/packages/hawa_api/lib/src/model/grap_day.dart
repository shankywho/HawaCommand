//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'grap_day.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GrapDay {
  /// Returns a new [GrapDay] instance.
  GrapDay({

    required  this.date,

    required  this.stage,

    required  this.probability,

     this.stageProbs,

     this.aqiP10,

     this.aqiP50,

     this.aqiP90,

     this.peakAt,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final DateTime date;



  @JsonKey(
    
    name: r'stage',
    required: true,
    includeIfNull: false,
  )


  final int stage;



  @JsonKey(
    
    name: r'probability',
    required: true,
    includeIfNull: false,
  )


  final double probability;



  @JsonKey(
    
    name: r'stage_probs',
    required: false,
    includeIfNull: false,
  )


  final List<double>? stageProbs;



  @JsonKey(
    
    name: r'aqi_p10',
    required: false,
    includeIfNull: false,
  )


  final int? aqiP10;



  @JsonKey(
    
    name: r'aqi_p50',
    required: false,
    includeIfNull: false,
  )


  final int? aqiP50;



  @JsonKey(
    
    name: r'aqi_p90',
    required: false,
    includeIfNull: false,
  )


  final int? aqiP90;



  @JsonKey(
    
    name: r'peak_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? peakAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GrapDay &&
      other.date == date &&
      other.stage == stage &&
      other.probability == probability &&
      other.stageProbs == stageProbs &&
      other.aqiP10 == aqiP10 &&
      other.aqiP50 == aqiP50 &&
      other.aqiP90 == aqiP90 &&
      other.peakAt == peakAt;

    @override
    int get hashCode =>
        date.hashCode +
        stage.hashCode +
        probability.hashCode +
        (stageProbs == null ? 0 : stageProbs.hashCode) +
        (aqiP10 == null ? 0 : aqiP10.hashCode) +
        (aqiP50 == null ? 0 : aqiP50.hashCode) +
        (aqiP90 == null ? 0 : aqiP90.hashCode) +
        (peakAt == null ? 0 : peakAt.hashCode);

  factory GrapDay.fromJson(Map<String, dynamic> json) => _$GrapDayFromJson(json);

  Map<String, dynamic> toJson() => _$GrapDayToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

