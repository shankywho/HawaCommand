//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum AlertAudience {
      @JsonValue(r'school')
      school(r'school'),
      @JsonValue(r'citizen')
      citizen(r'citizen'),
      @JsonValue(r'driver')
      driver(r'driver'),
      @JsonValue(r'inspector')
      inspector(r'inspector'),
      @JsonValue(r'officer')
      officer(r'officer'),
      @JsonValue(r'site_manager')
      siteManager(r'site_manager'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const AlertAudience(this.value);

  final String value;

  @override
  String toString() => value;
}
