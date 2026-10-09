//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum OtpChannel {
      @JsonValue(r'sms')
      sms(r'sms'),
      @JsonValue(r'whatsapp')
      whatsapp(r'whatsapp'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const OtpChannel(this.value);

  final String value;

  @override
  String toString() => value;
}
