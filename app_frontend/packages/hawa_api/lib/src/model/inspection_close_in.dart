//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/inspection_outcome.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_close_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InspectionCloseIn {
  /// Returns a new [InspectionCloseIn] instance.
  InspectionCloseIn({

    required  this.outcome,

    required  this.evidenceKeys,

    required  this.closedAt,

     this.notes,

     this.location,
  });

  @JsonKey(
    
    name: r'outcome',
    required: true,
    includeIfNull: false,
  unknownEnumValue: InspectionOutcome.unknownDefaultOpenApi,
  )


  final InspectionOutcome outcome;



  @JsonKey(
    
    name: r'evidence_keys',
    required: true,
    includeIfNull: false,
  )


  final List<String> evidenceKeys;



  @JsonKey(
    
    name: r'closed_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime closedAt;



  @JsonKey(
    
    name: r'notes',
    required: false,
    includeIfNull: false,
  )


  final String? notes;



  @JsonKey(
    
    name: r'location',
    required: false,
    includeIfNull: false,
  )


  final GeoPoint? location;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InspectionCloseIn &&
      other.outcome == outcome &&
      other.evidenceKeys == evidenceKeys &&
      other.closedAt == closedAt &&
      other.notes == notes &&
      other.location == location;

    @override
    int get hashCode =>
        outcome.hashCode +
        evidenceKeys.hashCode +
        closedAt.hashCode +
        (notes == null ? 0 : notes.hashCode) +
        location.hashCode;

  factory InspectionCloseIn.fromJson(Map<String, dynamic> json) => _$InspectionCloseInFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionCloseInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

