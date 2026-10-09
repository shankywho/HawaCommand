//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'ward_ref.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WardRef {
  /// Returns a new [WardRef] instance.
  WardRef({

    required  this.wardId,

     this.name,
  });

  @JsonKey(
    
    name: r'ward_id',
    required: true,
    includeIfNull: false,
  )


  final String wardId;



  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WardRef &&
      other.wardId == wardId &&
      other.name == name;

    @override
    int get hashCode =>
        wardId.hashCode +
        (name == null ? 0 : name.hashCode);

  factory WardRef.fromJson(Map<String, dynamic> json) => _$WardRefFromJson(json);

  Map<String, dynamic> toJson() => _$WardRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

