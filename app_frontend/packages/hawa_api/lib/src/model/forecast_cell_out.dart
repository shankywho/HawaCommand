//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/pollutant.dart';
import 'package:hawa_api/src/model/forecast_point.dart';
import 'package:hawa_api/src/model/forecast_daily.dart';
import 'package:json_annotation/json_annotation.dart';

part 'forecast_cell_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ForecastCellOut {
  /// Returns a new [ForecastCellOut] instance.
  ForecastCellOut({

    required  this.cellId,

    required  this.pollutant,

    required  this.issuedAt,

    required  this.series,

    required  this.isSimulated,

     this.requestedCellId,

     this.runId,

     this.modelVersion,

     this.daily,
  });

  @JsonKey(
    
    name: r'cell_id',
    required: true,
    includeIfNull: false,
  )


  final String cellId;



  @JsonKey(
    
    name: r'pollutant',
    required: true,
    includeIfNull: false,
  unknownEnumValue: Pollutant.unknownDefaultOpenApi,
  )


  final Pollutant pollutant;



  @JsonKey(
    
    name: r'issued_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime issuedAt;



  @JsonKey(
    
    name: r'series',
    required: true,
    includeIfNull: false,
  )


  final List<ForecastPoint> series;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'requested_cell_id',
    required: false,
    includeIfNull: false,
  )


  final String? requestedCellId;



  @JsonKey(
    
    name: r'run_id',
    required: false,
    includeIfNull: false,
  )


  final String? runId;



  @JsonKey(
    
    name: r'model_version',
    required: false,
    includeIfNull: false,
  )


  final String? modelVersion;



  @JsonKey(
    
    name: r'daily',
    required: false,
    includeIfNull: false,
  )


  final List<ForecastDaily>? daily;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ForecastCellOut &&
      other.cellId == cellId &&
      other.pollutant == pollutant &&
      other.issuedAt == issuedAt &&
      other.series == series &&
      other.isSimulated == isSimulated &&
      other.requestedCellId == requestedCellId &&
      other.runId == runId &&
      other.modelVersion == modelVersion &&
      other.daily == daily;

    @override
    int get hashCode =>
        cellId.hashCode +
        pollutant.hashCode +
        issuedAt.hashCode +
        series.hashCode +
        isSimulated.hashCode +
        (requestedCellId == null ? 0 : requestedCellId.hashCode) +
        (runId == null ? 0 : runId.hashCode) +
        (modelVersion == null ? 0 : modelVersion.hashCode) +
        (daily == null ? 0 : daily.hashCode);

  factory ForecastCellOut.fromJson(Map<String, dynamic> json) => _$ForecastCellOutFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastCellOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

