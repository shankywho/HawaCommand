//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ReportSource {
      @JsonValue(r'app')
      app(r'app'),
      @JsonValue(r'whatsapp')
      whatsapp(r'whatsapp'),
      @JsonValue(r'web')
      web(r'web'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const ReportSource(this.value);

  final String value;

  @override
  String toString() => value;
}
