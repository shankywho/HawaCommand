//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum InterventionSource {
      @JsonValue(r'hawatag')
      hawatag(r'hawatag'),
      @JsonValue(r'manual')
      manual(r'manual'),
      @JsonValue(r'gps_inferred')
      gpsInferred(r'gps_inferred'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const InterventionSource(this.value);

  final String value;

  @override
  String toString() => value;
}
