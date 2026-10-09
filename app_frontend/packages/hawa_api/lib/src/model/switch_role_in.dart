//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/user_role.dart';
import 'package:json_annotation/json_annotation.dart';

part 'switch_role_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SwitchRoleIn {
  /// Returns a new [SwitchRoleIn] instance.
  SwitchRoleIn({

    required  this.role,
  });

  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  unknownEnumValue: UserRole.unknownDefaultOpenApi,
  )


  final UserRole role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SwitchRoleIn &&
      other.role == role;

    @override
    int get hashCode =>
        role.hashCode;

  factory SwitchRoleIn.fromJson(Map<String, dynamic> json) => _$SwitchRoleInFromJson(json);

  Map<String, dynamic> toJson() => _$SwitchRoleInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

