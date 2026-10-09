//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/report_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_timeline_entry.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportTimelineEntry {
  /// Returns a new [ReportTimelineEntry] instance.
  ReportTimelineEntry({

    required  this.status,

    required  this.at,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ReportStatus.unknownDefaultOpenApi,
  )


  final ReportStatus status;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportTimelineEntry &&
      other.status == status &&
      other.at == at;

    @override
    int get hashCode =>
        status.hashCode +
        at.hashCode;

  factory ReportTimelineEntry.fromJson(Map<String, dynamic> json) => _$ReportTimelineEntryFromJson(json);

  Map<String, dynamic> toJson() => _$ReportTimelineEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

