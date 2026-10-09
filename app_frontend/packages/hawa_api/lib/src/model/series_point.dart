//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'series_point.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SeriesPoint {
  /// Returns a new [SeriesPoint] instance.
  SeriesPoint({

    required  this.ts,

    required  this.value,
  });

  @JsonKey(
    
    name: r'ts',
    required: true,
    includeIfNull: false,
  )


  final DateTime ts;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final double value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SeriesPoint &&
      other.ts == ts &&
      other.value == value;

    @override
    int get hashCode =>
        ts.hashCode +
        value.hashCode;

  factory SeriesPoint.fromJson(Map<String, dynamic> json) => _$SeriesPointFromJson(json);

  Map<String, dynamic> toJson() => _$SeriesPointToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

