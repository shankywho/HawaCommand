//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/pollutant.dart';
import 'package:hawa_api/src/model/impact_verdict.dart';
import 'package:hawa_api/src/model/impact_method.dart';
import 'package:json_annotation/json_annotation.dart';

part 'impact_summary.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ImpactSummary {
  /// Returns a new [ImpactSummary] instance.
  ImpactSummary({

    required  this.pollutant,

    required  this.effectPct,

    required  this.ciLow,

    required  this.ciHigh,

    required  this.method,

    required  this.verdict,

     this.durationMin,

     this.ciLevel,
  });

  @JsonKey(
    
    name: r'pollutant',
    required: true,
    includeIfNull: false,
  unknownEnumValue: Pollutant.unknownDefaultOpenApi,
  )


  final Pollutant pollutant;



  @JsonKey(
    
    name: r'effect_pct',
    required: true,
    includeIfNull: false,
  )


  final double effectPct;



  @JsonKey(
    
    name: r'ci_low',
    required: true,
    includeIfNull: false,
  )


  final double ciLow;



  @JsonKey(
    
    name: r'ci_high',
    required: true,
    includeIfNull: false,
  )


  final double ciHigh;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ImpactMethod.unknownDefaultOpenApi,
  )


  final ImpactMethod method;



  @JsonKey(
    
    name: r'verdict',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ImpactVerdict.unknownDefaultOpenApi,
  )


  final ImpactVerdict verdict;



  @JsonKey(
    
    name: r'duration_min',
    required: false,
    includeIfNull: false,
  )


  final int? durationMin;



  @JsonKey(
    
    name: r'ci_level',
    required: false,
    includeIfNull: false,
  )


  final double? ciLevel;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ImpactSummary &&
      other.pollutant == pollutant &&
      other.effectPct == effectPct &&
      other.ciLow == ciLow &&
      other.ciHigh == ciHigh &&
      other.method == method &&
      other.verdict == verdict &&
      other.durationMin == durationMin &&
      other.ciLevel == ciLevel;

    @override
    int get hashCode =>
        pollutant.hashCode +
        effectPct.hashCode +
        ciLow.hashCode +
        ciHigh.hashCode +
        method.hashCode +
        verdict.hashCode +
        (durationMin == null ? 0 : durationMin.hashCode) +
        (ciLevel == null ? 0 : ciLevel.hashCode);

  factory ImpactSummary.fromJson(Map<String, dynamic> json) => _$ImpactSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$ImpactSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

