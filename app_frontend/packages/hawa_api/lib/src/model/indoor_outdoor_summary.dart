//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'indoor_outdoor_summary.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class IndoorOutdoorSummary {
  /// Returns a new [IndoorOutdoorSummary] instance.
  IndoorOutdoorSummary({

     this.meanRatioInOut,

     this.hoursIndoorAbove60,

     this.alertsSent,
  });

  @JsonKey(
    
    name: r'mean_ratio_in_out',
    required: false,
    includeIfNull: false,
  )


  final double? meanRatioInOut;



  @JsonKey(
    
    name: r'hours_indoor_above_60',
    required: false,
    includeIfNull: false,
  )


  final double? hoursIndoorAbove60;



  @JsonKey(
    
    name: r'alerts_sent',
    required: false,
    includeIfNull: false,
  )


  final int? alertsSent;





    @override
    bool operator ==(Object other) => identical(this, other) || other is IndoorOutdoorSummary &&
      other.meanRatioInOut == meanRatioInOut &&
      other.hoursIndoorAbove60 == hoursIndoorAbove60 &&
      other.alertsSent == alertsSent;

    @override
    int get hashCode =>
        (meanRatioInOut == null ? 0 : meanRatioInOut.hashCode) +
        (hoursIndoorAbove60 == null ? 0 : hoursIndoorAbove60.hashCode) +
        (alertsSent == null ? 0 : alertsSent.hashCode);

  factory IndoorOutdoorSummary.fromJson(Map<String, dynamic> json) => _$IndoorOutdoorSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$IndoorOutdoorSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

