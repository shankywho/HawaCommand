//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum AlertKind {
      @JsonValue(r'pollutant_warning')
      pollutantWarning(r'pollutant_warning'),
      @JsonValue(r'safe_window')
      safeWindow(r'safe_window'),
      @JsonValue(r'route_assignment')
      routeAssignment(r'route_assignment'),
      @JsonValue(r'inspection_target')
      inspectionTarget(r'inspection_target'),
      @JsonValue(r'grap_outlook')
      grapOutlook(r'grap_outlook'),
      @JsonValue(r'report_outcome')
      reportOutcome(r'report_outcome'),
      @JsonValue(r'device_health')
      deviceHealth(r'device_health'),
      @JsonValue(r'route_changed')
      routeChanged(r'route_changed'),
      @JsonValue(r'task_done_auto')
      taskDoneAuto(r'task_done_auto'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const AlertKind(this.value);

  final String value;

  @override
  String toString() => value;
}
