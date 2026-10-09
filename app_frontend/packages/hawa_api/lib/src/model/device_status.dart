//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum DeviceStatus {
      @JsonValue(r'provisioned')
      provisioned(r'provisioned'),
      @JsonValue(r'active')
      active(r'active'),
      @JsonValue(r'degraded')
      degraded(r'degraded'),
      @JsonValue(r'offline')
      offline(r'offline'),
      @JsonValue(r'retired')
      retired(r'retired'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const DeviceStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
