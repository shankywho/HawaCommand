//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:json_annotation/json_annotation.dart';

part 'evidence_summary.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EvidenceSummary {
  /// Returns a new [EvidenceSummary] instance.
  EvidenceSummary({

     this.spikeRatio,

     this.photoLabel,

     this.photoConf,

     this.firePoints,
  });

  @JsonKey(
    
    name: r'spike_ratio',
    required: false,
    includeIfNull: false,
  )


  final double? spikeRatio;



  @JsonKey(
    
    name: r'photo_label',
    required: false,
    includeIfNull: false,
  unknownEnumValue: CauseLabel.unknownDefaultOpenApi,
  )


  final CauseLabel? photoLabel;



  @JsonKey(
    
    name: r'photo_conf',
    required: false,
    includeIfNull: false,
  )


  final double? photoConf;



  @JsonKey(
    
    name: r'fire_points',
    required: false,
    includeIfNull: false,
  )


  final int? firePoints;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EvidenceSummary &&
      other.spikeRatio == spikeRatio &&
      other.photoLabel == photoLabel &&
      other.photoConf == photoConf &&
      other.firePoints == firePoints;

    @override
    int get hashCode =>
        (spikeRatio == null ? 0 : spikeRatio.hashCode) +
        photoLabel.hashCode +
        (photoConf == null ? 0 : photoConf.hashCode) +
        (firePoints == null ? 0 : firePoints.hashCode);

  factory EvidenceSummary.fromJson(Map<String, dynamic> json) => _$EvidenceSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$EvidenceSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

