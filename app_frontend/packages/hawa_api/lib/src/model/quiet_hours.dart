//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'quiet_hours.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class QuietHours {
  /// Returns a new [QuietHours] instance.
  QuietHours({

    required  this.start,

    required  this.end,
  });

  @JsonKey(
    
    name: r'start',
    required: true,
    includeIfNull: false,
  )


  final String start;



  @JsonKey(
    
    name: r'end',
    required: true,
    includeIfNull: false,
  )


  final String end;





    @override
    bool operator ==(Object other) => identical(this, other) || other is QuietHours &&
      other.start == start &&
      other.end == end;

    @override
    int get hashCode =>
        start.hashCode +
        end.hashCode;

  factory QuietHours.fromJson(Map<String, dynamic> json) => _$QuietHoursFromJson(json);

  Map<String, dynamic> toJson() => _$QuietHoursToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

