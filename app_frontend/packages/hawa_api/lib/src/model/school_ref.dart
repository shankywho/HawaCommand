//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'school_ref.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolRef {
  /// Returns a new [SchoolRef] instance.
  SchoolRef({

    required  this.schoolId,

    required  this.name,

     this.nameHi,
  });

  @JsonKey(
    
    name: r'school_id',
    required: true,
    includeIfNull: false,
  )


  final String schoolId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'name_hi',
    required: false,
    includeIfNull: false,
  )


  final String? nameHi;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SchoolRef &&
      other.schoolId == schoolId &&
      other.name == name &&
      other.nameHi == nameHi;

    @override
    int get hashCode =>
        schoolId.hashCode +
        name.hashCode +
        (nameHi == null ? 0 : nameHi.hashCode);

  factory SchoolRef.fromJson(Map<String, dynamic> json) => _$SchoolRefFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

