//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum SiteType {
      @JsonValue(r'construction')
      construction(r'construction'),
      @JsonValue(r'industrial_unit')
      industrialUnit(r'industrial_unit'),
      @JsonValue(r'waste_site')
      wasteSite(r'waste_site'),
      @JsonValue(r'other')
      other(r'other'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const SiteType(this.value);

  final String value;

  @override
  String toString() => value;
}
