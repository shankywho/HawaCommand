//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'quantile_value.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuantileValue {
  /// Returns a new [QuantileValue] instance.
  QuantileValue({

    required  this.p50,

     this.p10,

     this.p90,

     this.at,
  });

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
    
    name: r'at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? at;





    @override
    bool operator ==(Object other) => identical(this, other) || other is QuantileValue &&
      other.p50 == p50 &&
      other.p10 == p10 &&
      other.p90 == p90 &&
      other.at == at;

    @override
    int get hashCode =>
        p50.hashCode +
        (p10 == null ? 0 : p10.hashCode) +
        (p90 == null ? 0 : p90.hashCode) +
        (at == null ? 0 : at.hashCode);

  factory QuantileValue.fromJson(Map<String, dynamic> json) => _$QuantileValueFromJson(json);

  Map<String, dynamic> toJson() => _$QuantileValueToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

