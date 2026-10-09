//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum AqiCategory {
      @JsonValue(r'good')
      good(r'good'),
      @JsonValue(r'satisfactory')
      satisfactory(r'satisfactory'),
      @JsonValue(r'moderate')
      moderate(r'moderate'),
      @JsonValue(r'poor')
      poor(r'poor'),
      @JsonValue(r'very_poor')
      veryPoor(r'very_poor'),
      @JsonValue(r'severe')
      severe(r'severe'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const AqiCategory(this.value);

  final String value;

  @override
  String toString() => value;
}
