//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/pollutant.dart';
import 'package:hawa_api/src/model/series_point.dart';
import 'package:json_annotation/json_annotation.dart';

part 'spike_evidence.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SpikeEvidence {
  /// Returns a new [SpikeEvidence] instance.
  SpikeEvidence({

    required  this.pollutant,

    required  this.baseline,

    required  this.peak,

    required  this.series,

     this.deviceId,

     this.vehicleLabel,

     this.durationS,

     this.detectedAt,
  });

  @JsonKey(
    
    name: r'pollutant',
    required: true,
    includeIfNull: false,
  unknownEnumValue: Pollutant.unknownDefaultOpenApi,
  )


  final Pollutant pollutant;



  @JsonKey(
    
    name: r'baseline',
    required: true,
    includeIfNull: false,
  )


  final double baseline;



  @JsonKey(
    
    name: r'peak',
    required: true,
    includeIfNull: false,
  )


  final double peak;



  @JsonKey(
    
    name: r'series',
    required: true,
    includeIfNull: false,
  )


  final List<SeriesPoint> series;



  @JsonKey(
    
    name: r'device_id',
    required: false,
    includeIfNull: false,
  )


  final String? deviceId;



  @JsonKey(
    
    name: r'vehicle_label',
    required: false,
    includeIfNull: false,
  )


  final String? vehicleLabel;



  @JsonKey(
    
    name: r'duration_s',
    required: false,
    includeIfNull: false,
  )


  final int? durationS;



  @JsonKey(
    
    name: r'detected_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? detectedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SpikeEvidence &&
      other.pollutant == pollutant &&
      other.baseline == baseline &&
      other.peak == peak &&
      other.series == series &&
      other.deviceId == deviceId &&
      other.vehicleLabel == vehicleLabel &&
      other.durationS == durationS &&
      other.detectedAt == detectedAt;

    @override
    int get hashCode =>
        pollutant.hashCode +
        baseline.hashCode +
        peak.hashCode +
        series.hashCode +
        (deviceId == null ? 0 : deviceId.hashCode) +
        (vehicleLabel == null ? 0 : vehicleLabel.hashCode) +
        (durationS == null ? 0 : durationS.hashCode) +
        (detectedAt == null ? 0 : detectedAt.hashCode);

  factory SpikeEvidence.fromJson(Map<String, dynamic> json) => _$SpikeEvidenceFromJson(json);

  Map<String, dynamic> toJson() => _$SpikeEvidenceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

