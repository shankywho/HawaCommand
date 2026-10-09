//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/grap_day.dart';
import 'package:json_annotation/json_annotation.dart';

part 'grap_outlook_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GrapOutlookOut {
  /// Returns a new [GrapOutlookOut] instance.
  GrapOutlookOut({

    required  this.wardId,

    required  this.issuedAt,

    required  this.days,

    required  this.isSimulated,

     this.modelVersion,

     this.checklistStage,

     this.note,
  });

  @JsonKey(
    
    name: r'ward_id',
    required: true,
    includeIfNull: false,
  )


  final String wardId;



  @JsonKey(
    
    name: r'issued_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime issuedAt;



  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final List<GrapDay> days;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'model_version',
    required: false,
    includeIfNull: false,
  )


  final String? modelVersion;



  @JsonKey(
    
    name: r'checklist_stage',
    required: false,
    includeIfNull: false,
  )


  final int? checklistStage;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GrapOutlookOut &&
      other.wardId == wardId &&
      other.issuedAt == issuedAt &&
      other.days == days &&
      other.isSimulated == isSimulated &&
      other.modelVersion == modelVersion &&
      other.checklistStage == checklistStage &&
      other.note == note;

    @override
    int get hashCode =>
        wardId.hashCode +
        issuedAt.hashCode +
        days.hashCode +
        isSimulated.hashCode +
        (modelVersion == null ? 0 : modelVersion.hashCode) +
        (checklistStage == null ? 0 : checklistStage.hashCode) +
        (note == null ? 0 : note.hashCode);

  factory GrapOutlookOut.fromJson(Map<String, dynamic> json) => _$GrapOutlookOutFromJson(json);

  Map<String, dynamic> toJson() => _$GrapOutlookOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

