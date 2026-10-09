//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/pollutant.dart';
import 'package:hawa_api/src/model/aqi_category.dart';
import 'package:hawa_api/src/model/cause_label.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'open_air_properties.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OpenAirProperties {
  /// Returns a new [OpenAirProperties] instance.
  OpenAirProperties({

    required  this.cellId,

    required  this.confidence,

    required  this.aqi,

    required  this.aqiCategory,

    required  this.isSimulated,

     this.pm25,

     this.pm10,

     this.no2Ppb,

     this.dominantPollutant,

     this.causeLabel,

     this.causeConf,

     this.placeName,
  });

  @JsonKey(
    
    name: r'cell_id',
    required: true,
    includeIfNull: false,
  )


  final String cellId;



  @JsonKey(
    
    name: r'confidence',
    required: true,
    includeIfNull: false,
  )


  final double confidence;



  @JsonKey(
    
    name: r'aqi',
    required: true,
    includeIfNull: false,
  )


  final int aqi;



  @JsonKey(
    
    name: r'aqi_category',
    required: true,
    includeIfNull: false,
  unknownEnumValue: AqiCategory.unknownDefaultOpenApi,
  )


  final AqiCategory aqiCategory;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'pm25',
    required: false,
    includeIfNull: false,
  )


  final double? pm25;



  @JsonKey(
    
    name: r'pm10',
    required: false,
    includeIfNull: false,
  )


  final double? pm10;



  @JsonKey(
    
    name: r'no2_ppb',
    required: false,
    includeIfNull: false,
  )


  final double? no2Ppb;



  @JsonKey(
    
    name: r'dominant_pollutant',
    required: false,
    includeIfNull: false,
  unknownEnumValue: Pollutant.unknownDefaultOpenApi,
  )


  final Pollutant? dominantPollutant;



  @JsonKey(
    
    name: r'cause_label',
    required: false,
    includeIfNull: false,
  unknownEnumValue: CauseLabel.unknownDefaultOpenApi,
  )


  final CauseLabel? causeLabel;



  @JsonKey(
    
    name: r'cause_conf',
    required: false,
    includeIfNull: false,
  )


  final double? causeConf;



  @JsonKey(
    
    name: r'place_name',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? placeName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OpenAirProperties &&
      other.cellId == cellId &&
      other.confidence == confidence &&
      other.aqi == aqi &&
      other.aqiCategory == aqiCategory &&
      other.isSimulated == isSimulated &&
      other.pm25 == pm25 &&
      other.pm10 == pm10 &&
      other.no2Ppb == no2Ppb &&
      other.dominantPollutant == dominantPollutant &&
      other.causeLabel == causeLabel &&
      other.causeConf == causeConf &&
      other.placeName == placeName;

    @override
    int get hashCode =>
        cellId.hashCode +
        confidence.hashCode +
        aqi.hashCode +
        aqiCategory.hashCode +
        isSimulated.hashCode +
        (pm25 == null ? 0 : pm25.hashCode) +
        (pm10 == null ? 0 : pm10.hashCode) +
        (no2Ppb == null ? 0 : no2Ppb.hashCode) +
        dominantPollutant.hashCode +
        causeLabel.hashCode +
        (causeConf == null ? 0 : causeConf.hashCode) +
        placeName.hashCode;

  factory OpenAirProperties.fromJson(Map<String, dynamic> json) => _$OpenAirPropertiesFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAirPropertiesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

