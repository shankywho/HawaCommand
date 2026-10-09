//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'forecast_daily.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForecastDaily {
  /// Returns a new [ForecastDaily] instance.
  ForecastDaily({

    required  this.date,

     this.maxP50,

     this.maxP90,

     this.grapStage,

     this.peakAt,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final DateTime date;



  @JsonKey(
    
    name: r'max_p50',
    required: false,
    includeIfNull: false,
  )


  final double? maxP50;



  @JsonKey(
    
    name: r'max_p90',
    required: false,
    includeIfNull: false,
  )


  final double? maxP90;



  @JsonKey(
    
    name: r'grap_stage',
    required: false,
    includeIfNull: false,
  )


  final int? grapStage;



  @JsonKey(
    
    name: r'peak_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? peakAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ForecastDaily &&
      other.date == date &&
      other.maxP50 == maxP50 &&
      other.maxP90 == maxP90 &&
      other.grapStage == grapStage &&
      other.peakAt == peakAt;

    @override
    int get hashCode =>
        date.hashCode +
        (maxP50 == null ? 0 : maxP50.hashCode) +
        (maxP90 == null ? 0 : maxP90.hashCode) +
        (grapStage == null ? 0 : grapStage.hashCode) +
        (peakAt == null ? 0 : peakAt.hashCode);

  factory ForecastDaily.fromJson(Map<String, dynamic> json) => _$ForecastDailyFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastDailyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

