//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ImpactMethod {
      @JsonValue(r'synthetic_control')
      syntheticControl(r'synthetic_control'),
      @JsonValue(r'diff_in_diff')
      diffInDiff(r'diff_in_diff'),
      @JsonValue(r'before_after_naive')
      beforeAfterNaive(r'before_after_naive'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const ImpactMethod(this.value);

  final String value;

  @override
  String toString() => value;
}
