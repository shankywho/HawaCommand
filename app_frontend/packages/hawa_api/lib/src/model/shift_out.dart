//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/shift_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'shift_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ShiftOut {
  /// Returns a new [ShiftOut] instance.
  ShiftOut({

    required  this.shiftId,

    required  this.status,

     this.startedAt,

     this.endedAt,
  });

  @JsonKey(
    
    name: r'shift_id',
    required: true,
    includeIfNull: false,
  )


  final String shiftId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: ShiftStatus.unknownDefaultOpenApi,
  )


  final ShiftStatus status;



  @JsonKey(
    
    name: r'started_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? startedAt;



  @JsonKey(
    
    name: r'ended_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? endedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ShiftOut &&
      other.shiftId == shiftId &&
      other.status == status &&
      other.startedAt == startedAt &&
      other.endedAt == endedAt;

    @override
    int get hashCode =>
        shiftId.hashCode +
        status.hashCode +
        (startedAt == null ? 0 : startedAt.hashCode) +
        (endedAt == null ? 0 : endedAt.hashCode);

  factory ShiftOut.fromJson(Map<String, dynamic> json) => _$ShiftOutFromJson(json);

  Map<String, dynamic> toJson() => _$ShiftOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

