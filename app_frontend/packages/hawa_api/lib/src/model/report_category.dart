//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ReportCategory {
      @JsonValue(r'burning')
      burning(r'burning'),
      @JsonValue(r'dust')
      dust(r'dust'),
      @JsonValue(r'other')
      other(r'other'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const ReportCategory(this.value);

  final String value;

  @override
  String toString() => value;
}
