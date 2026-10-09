//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum AlertStatus {
      @JsonValue(r'requested')
      requested(r'requested'),
      @JsonValue(r'queued')
      queued(r'queued'),
      @JsonValue(r'sent')
      sent(r'sent'),
      @JsonValue(r'delivered')
      delivered(r'delivered'),
      @JsonValue(r'failed')
      failed(r'failed'),
      @JsonValue(r'read')
      read(r'read'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const AlertStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
