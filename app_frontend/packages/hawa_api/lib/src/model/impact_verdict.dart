//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ImpactVerdict {
      @JsonValue(r'effective')
      effective(r'effective'),
      @JsonValue(r'no_detectable_effect')
      noDetectableEffect(r'no_detectable_effect'),
      @JsonValue(r'inconclusive')
      inconclusive(r'inconclusive'),
      @JsonValue(r'adverse')
      adverse(r'adverse'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const ImpactVerdict(this.value);

  final String value;

  @override
  String toString() => value;
}
