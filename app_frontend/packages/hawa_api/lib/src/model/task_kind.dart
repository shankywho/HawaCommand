//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum TaskKind {
      @JsonValue(r'spray')
      spray(r'spray'),
      @JsonValue(r'sweep')
      sweep(r'sweep'),
      @JsonValue(r'inspect')
      inspect(r'inspect'),
      @JsonValue(r'protect_alert')
      protectAlert(r'protect_alert'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const TaskKind(this.value);

  final String value;

  @override
  String toString() => value;
}
