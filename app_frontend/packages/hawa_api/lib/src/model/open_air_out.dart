//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/open_air_feature.dart';
import 'package:hawa_api/src/model/licence.dart';
import 'package:hawa_api/src/model/citizen_advice.dart';
import 'package:json_annotation/json_annotation.dart';

part 'open_air_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OpenAirOut {
  /// Returns a new [OpenAirOut] instance.
  OpenAirOut({

    required  this.type,

    required  this.asOf,

    required  this.features,

     this.resolutionM,

     this.aqiBasis,

     this.licence,

     this.methodsUrl,

     this.advice,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final String type;



  @JsonKey(
    
    name: r'as_of',
    required: true,
    includeIfNull: false,
  )


  final DateTime asOf;



  @JsonKey(
    
    name: r'features',
    required: true,
    includeIfNull: false,
  )


  final List<OpenAirFeature> features;



  @JsonKey(
    
    name: r'resolution_m',
    required: false,
    includeIfNull: false,
  )


  final int? resolutionM;



  @JsonKey(
    
    name: r'aqi_basis',
    required: false,
    includeIfNull: false,
  )


  final String? aqiBasis;



  @JsonKey(
    
    name: r'licence',
    required: false,
    includeIfNull: false,
  )


  final Licence? licence;



  @JsonKey(
    
    name: r'methods_url',
    required: false,
    includeIfNull: false,
  )


  final String? methodsUrl;



  @JsonKey(
    
    name: r'advice',
    required: false,
    includeIfNull: false,
  )


  final CitizenAdvice? advice;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OpenAirOut &&
      other.type == type &&
      other.asOf == asOf &&
      other.features == features &&
      other.resolutionM == resolutionM &&
      other.aqiBasis == aqiBasis &&
      other.licence == licence &&
      other.methodsUrl == methodsUrl &&
      other.advice == advice;

    @override
    int get hashCode =>
        type.hashCode +
        asOf.hashCode +
        features.hashCode +
        (resolutionM == null ? 0 : resolutionM.hashCode) +
        (aqiBasis == null ? 0 : aqiBasis.hashCode) +
        licence.hashCode +
        (methodsUrl == null ? 0 : methodsUrl.hashCode) +
        advice.hashCode;

  factory OpenAirOut.fromJson(Map<String, dynamic> json) => _$OpenAirOutFromJson(json);

  Map<String, dynamic> toJson() => _$OpenAirOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

