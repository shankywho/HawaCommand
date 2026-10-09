//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/auth_user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'token_response.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TokenResponse {
  /// Returns a new [TokenResponse] instance.
  TokenResponse({

    required  this.accessToken,

    required  this.tokenType,

    required  this.expiresIn,

    required  this.refreshToken,

    required  this.user,

     this.refreshExpiresIn,
  });

  @JsonKey(
    
    name: r'access_token',
    required: true,
    includeIfNull: false,
  )


  final String accessToken;



  @JsonKey(
    
    name: r'token_type',
    required: true,
    includeIfNull: false,
  )


  final String tokenType;



  @JsonKey(
    
    name: r'expires_in',
    required: true,
    includeIfNull: false,
  )


  final int expiresIn;



  @JsonKey(
    
    name: r'refresh_token',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;



  @JsonKey(
    
    name: r'user',
    required: true,
    includeIfNull: false,
  )


  final AuthUser user;



  @JsonKey(
    
    name: r'refresh_expires_in',
    required: false,
    includeIfNull: false,
  )


  final int? refreshExpiresIn;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TokenResponse &&
      other.accessToken == accessToken &&
      other.tokenType == tokenType &&
      other.expiresIn == expiresIn &&
      other.refreshToken == refreshToken &&
      other.user == user &&
      other.refreshExpiresIn == refreshExpiresIn;

    @override
    int get hashCode =>
        accessToken.hashCode +
        tokenType.hashCode +
        expiresIn.hashCode +
        refreshToken.hashCode +
        user.hashCode +
        (refreshExpiresIn == null ? 0 : refreshExpiresIn.hashCode);

  factory TokenResponse.fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

