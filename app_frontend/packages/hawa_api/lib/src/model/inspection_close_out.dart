//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/inspection_status.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_close_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InspectionCloseOut {
  /// Returns a new [InspectionCloseOut] instance.
  InspectionCloseOut({

    required  this.id,

    required  this.status,

     this.closedAt,

     this.applied,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  unknownEnumValue: InspectionStatus.unknownDefaultOpenApi,
  )


  final InspectionStatus status;



  @JsonKey(
    
    name: r'closed_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? closedAt;



  @JsonKey(
    
    name: r'applied',
    required: false,
    includeIfNull: false,
  )


  final bool? applied;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InspectionCloseOut &&
      other.id == id &&
      other.status == status &&
      other.closedAt == closedAt &&
      other.applied == applied;

    @override
    int get hashCode =>
        id.hashCode +
        status.hashCode +
        (closedAt == null ? 0 : closedAt.hashCode) +
        (applied == null ? 0 : applied.hashCode);

  factory InspectionCloseOut.fromJson(Map<String, dynamic> json) => _$InspectionCloseOutFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionCloseOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

