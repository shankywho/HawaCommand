//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/site_ref.dart';
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/user_role.dart';
import 'package:hawa_api/src/model/me_features.dart';
import 'package:hawa_api/src/model/ward_ref.dart';
import 'package:hawa_api/src/model/school_ref.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeOut {
  /// Returns a new [MeOut] instance.
  MeOut({

    required  this.id,

    required  this.role,

    required  this.displayName,

    required  this.lang,

    required  this.isSimulated,

     this.roles,

     this.email,

     this.phoneE164,

     this.wards,

     this.assetIds,

     this.school,

     this.site,

     this.currentShift,

     this.features,

     this.notificationPrefs,
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
    
    name: r'email',
    required: false,
    includeIfNull: false,
  )


  final String? email;



  @JsonKey(
    
    name: r'phone_e164',
    required: false,
    includeIfNull: false,
  )


  final String? phoneE164;



  @JsonKey(
    
    name: r'wards',
    required: false,
    includeIfNull: false,
  )


  final List<WardRef>? wards;



  @JsonKey(
    
    name: r'asset_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? assetIds;



  @JsonKey(
    
    name: r'school',
    required: false,
    includeIfNull: false,
  )


  final SchoolRef? school;



  @JsonKey(
    
    name: r'site',
    required: false,
    includeIfNull: false,
  )


  final SiteRef? site;



  @JsonKey(
    
    name: r'current_shift',
    required: false,
    includeIfNull: false,
  )


  final String? currentShift;



  @JsonKey(
    
    name: r'features',
    required: false,
    includeIfNull: false,
  )


  final MeFeatures? features;



  @JsonKey(
    
    name: r'notification_prefs',
    required: false,
    includeIfNull: false,
  )


  final Map<String, bool>? notificationPrefs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MeOut &&
      other.id == id &&
      other.role == role &&
      other.displayName == displayName &&
      other.lang == lang &&
      other.isSimulated == isSimulated &&
      other.roles == roles &&
      other.email == email &&
      other.phoneE164 == phoneE164 &&
      other.wards == wards &&
      other.assetIds == assetIds &&
      other.school == school &&
      other.site == site &&
      other.currentShift == currentShift &&
      other.features == features &&
      other.notificationPrefs == notificationPrefs;

    @override
    int get hashCode =>
        id.hashCode +
        role.hashCode +
        displayName.hashCode +
        lang.hashCode +
        isSimulated.hashCode +
        (roles == null ? 0 : roles.hashCode) +
        (email == null ? 0 : email.hashCode) +
        (phoneE164 == null ? 0 : phoneE164.hashCode) +
        (wards == null ? 0 : wards.hashCode) +
        (assetIds == null ? 0 : assetIds.hashCode) +
        school.hashCode +
        site.hashCode +
        (currentShift == null ? 0 : currentShift.hashCode) +
        features.hashCode +
        (notificationPrefs == null ? 0 : notificationPrefs.hashCode);

  factory MeOut.fromJson(Map<String, dynamic> json) => _$MeOutFromJson(json);

  Map<String, dynamic> toJson() => _$MeOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

