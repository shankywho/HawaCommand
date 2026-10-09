//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum Pollutant {
      @JsonValue(r'pm1')
      pm1(r'pm1'),
      @JsonValue(r'pm25')
      pm25(r'pm25'),
      @JsonValue(r'pm10')
      pm10(r'pm10'),
      @JsonValue(r'no2')
      no2(r'no2'),
      @JsonValue(r'co')
      co(r'co'),
      @JsonValue(r'nh3')
      nh3(r'nh3'),
      @JsonValue(r'voc')
      voc(r'voc'),
      @JsonValue(r'co2')
      co2(r'co2'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const Pollutant(this.value);

  final String value;

  @override
  String toString() => value;
}
