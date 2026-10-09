//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/user_role.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_user.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AuthUser {
  /// Returns a new [AuthUser] instance.
  AuthUser({

    required  this.id,

    required  this.role,

    required  this.displayName,

    required  this.lang,

    required  this.isSimulated,

     this.roles,

     this.wards,

     this.assetIds,

     this.schoolId,

     this.siteId,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  unknownEnumValue: UserRole.unknownDefaultOpenApi,
  )


  final UserRole role;



  @JsonKey(
    
    name: r'display_name',
    required: true,
    includeIfNull: false,
  )


  final String displayName;



  @JsonKey(
    
    name: r'lang',
    required: true,
    includeIfNull: false,
  unknownEnumValue: Lang.unknownDefaultOpenApi,
  )


  final Lang lang;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'roles',
    required: false,
    includeIfNull: false,
  )


  final List<UserRole>? roles;



  @JsonKey(
    
    name: r'wards',
    required: false,
    includeIfNull: false,
  )


  final List<String>? wards;



  @JsonKey(
    
    name: r'asset_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? assetIds;



  @JsonKey(
    
    name: r'school_id',
    required: false,
    includeIfNull: false,
  )


  final String? schoolId;



  @JsonKey(
    
    name: r'site_id',
    required: false,
    includeIfNull: false,
  )


  final String? siteId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AuthUser &&
      other.id == id &&
      other.role == role &&
      other.displayName == displayName &&
      other.lang == lang &&
      other.isSimulated == isSimulated &&
      other.roles == roles &&
      other.wards == wards &&
      other.assetIds == assetIds &&
      other.schoolId == schoolId &&
      other.siteId == siteId;

    @override
    int get hashCode =>
        id.hashCode +
        role.hashCode +
        displayName.hashCode +
        lang.hashCode +
        isSimulated.hashCode +
        (roles == null ? 0 : roles.hashCode) +
        (wards == null ? 0 : wards.hashCode) +
        (assetIds == null ? 0 : assetIds.hashCode) +
        (schoolId == null ? 0 : schoolId.hashCode) +
        (siteId == null ? 0 : siteId.hashCode);

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

  Map<String, dynamic> toJson() => _$AuthUserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

