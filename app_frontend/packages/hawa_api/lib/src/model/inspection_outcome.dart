//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum InspectionOutcome {
      @JsonValue(r'closed_confirmed')
      closedConfirmed(r'closed_confirmed'),
      @JsonValue(r'closed_not_found')
      closedNotFound(r'closed_not_found'),
      @JsonValue(r'closed_unreachable')
      closedUnreachable(r'closed_unreachable'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const InspectionOutcome(this.value);

  final String value;

  @override
  String toString() => value;
}
