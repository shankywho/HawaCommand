//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum PushPlatform {
      @JsonValue(r'android')
      android(r'android'),
      @JsonValue(r'ios')
      ios(r'ios'),
      @JsonValue(r'web')
      web(r'web'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const PushPlatform(this.value);

  final String value;

  @override
  String toString() => value;
}
