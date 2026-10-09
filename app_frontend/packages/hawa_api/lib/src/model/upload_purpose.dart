//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum UploadPurpose {
      @JsonValue(r'report_photo')
      reportPhoto(r'report_photo'),
      @JsonValue(r'inspection_photo')
      inspectionPhoto(r'inspection_photo'),
      @JsonValue(r'task_photo')
      taskPhoto(r'task_photo'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const UploadPurpose(this.value);

  final String value;

  @override
  String toString() => value;
}
