//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum TaskStatus {
      @JsonValue(r'pending')
      pending(r'pending'),
      @JsonValue(r'dispatched')
      dispatched(r'dispatched'),
      @JsonValue(r'acknowledged')
      acknowledged(r'acknowledged'),
      @JsonValue(r'en_route')
      enRoute(r'en_route'),
      @JsonValue(r'in_progress')
      inProgress(r'in_progress'),
      @JsonValue(r'done')
      done(r'done'),
      @JsonValue(r'verifying')
      verifying(r'verifying'),
      @JsonValue(r'verified')
      verified(r'verified'),
      @JsonValue(r'inconclusive')
      inconclusive(r'inconclusive'),
      @JsonValue(r'skipped')
      skipped(r'skipped'),
      @JsonValue(r'cancelled')
      cancelled(r'cancelled'),
      @JsonValue(r'missed')
      missed(r'missed'),
      @JsonValue(r'failed')
      failed(r'failed'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const TaskStatus(this.value);

  final String value;

  @override
  String toString() => value;
}
