//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'pm10_trend_point.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Pm10TrendPoint {
  /// Returns a new [Pm10TrendPoint] instance.
  Pm10TrendPoint({

    required  this.date,

     this.pm10P50,

     this.nObs,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final DateTime date;



  @JsonKey(
    
    name: r'pm10_p50',
    required: false,
    includeIfNull: false,
  )


  final double? pm10P50;



  @JsonKey(
    
    name: r'n_obs',
    required: false,
    includeIfNull: false,
  )


  final int? nObs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Pm10TrendPoint &&
      other.date == date &&
      other.pm10P50 == pm10P50 &&
      other.nObs == nObs;

    @override
    int get hashCode =>
        date.hashCode +
        (pm10P50 == null ? 0 : pm10P50.hashCode) +
        (nObs == null ? 0 : nObs.hashCode);

  factory Pm10TrendPoint.fromJson(Map<String, dynamic> json) => _$Pm10TrendPointFromJson(json);

  Map<String, dynamic> toJson() => _$Pm10TrendPointToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

