//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum CauseLabel {
      @JsonValue(r'dust')
      dust(r'dust'),
      @JsonValue(r'traffic')
      traffic(r'traffic'),
      @JsonValue(r'burning')
      burning(r'burning'),
      @JsonValue(r'regional_smoke')
      regionalSmoke(r'regional_smoke'),
      @JsonValue(r'mixed')
      mixed(r'mixed'),
      @JsonValue(r'unknown')
      unknown(r'unknown'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const CauseLabel(this.value);

  final String value;

  @override
  String toString() => value;
}
