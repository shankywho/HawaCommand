//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ReportStatus {
      @JsonValue(r'submitted')
      submitted(r'submitted'),
      @JsonValue(r'verifying')
      verifying(r'verifying'),
      @JsonValue(r'verified')
      verified(r'verified'),
      @JsonValue(r'rejected')
      rejected(r'rejected'),
      @JsonValue(r'ticketed')
      ticketed(r'ticketed'),
      @JsonValue(r'closed')
      closed(r'closed'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const ReportStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
