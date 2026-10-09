//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum InspectionStatus {
      @JsonValue(r'open')
      open(r'open'),
      @JsonValue(r'assigned')
      assigned(r'assigned'),
      @JsonValue(r'on_site')
      onSite(r'on_site'),
      @JsonValue(r'closed_confirmed')
      closedConfirmed(r'closed_confirmed'),
      @JsonValue(r'closed_not_found')
      closedNotFound(r'closed_not_found'),
      @JsonValue(r'closed_unreachable')
      closedUnreachable(r'closed_unreachable'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const InspectionStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
