//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum SkipReason {
      @JsonValue(r'road_blocked')
      roadBlocked(r'road_blocked'),
      @JsonValue(r'vehicle_issue')
      vehicleIssue(r'vehicle_issue'),
      @JsonValue(r'water_empty')
      waterEmpty(r'water_empty'),
      @JsonValue(r'unsafe')
      unsafe(r'unsafe'),
      @JsonValue(r'access_denied')
      accessDenied(r'access_denied'),
      @JsonValue(r'other')
      other(r'other'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const SkipReason(this.value);

  final String value;

  @override
  String toString() => value;
}
