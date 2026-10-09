//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ShiftStatus {
      @JsonValue(r'scheduled')
      scheduled(r'scheduled'),
      @JsonValue(r'active')
      active(r'active'),
      @JsonValue(r'ended')
      ended(r'ended'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const ShiftStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
