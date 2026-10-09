//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum InspectionOrigin {
      @JsonValue(r'report')
      report(r'report'),
      @JsonValue(r'spike')
      spike(r'spike'),
      @JsonValue(r'hotspot')
      hotspot(r'hotspot'),
      @JsonValue(r'plan')
      plan(r'plan'),
      @JsonValue(r'manual')
      manual(r'manual'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const InspectionOrigin(this.value);

  final String value;

  @override
  String toString() => value;
}
