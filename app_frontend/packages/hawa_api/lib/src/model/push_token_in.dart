//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/push_platform.dart';
import 'package:json_annotation/json_annotation.dart';

part 'push_token_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PushTokenIn {
  /// Returns a new [PushTokenIn] instance.
  PushTokenIn({

    required  this.token,

    required  this.platform,

     this.appFlavor,

     this.appVersion,

     this.locale,

     this.deviceLabel,
  });

  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  unknownEnumValue: PushPlatform.unknownDefaultOpenApi,
  )


  final PushPlatform platform;



  @JsonKey(
    
    name: r'app_flavor',
    required: false,
    includeIfNull: false,
  )


  final String? appFlavor;



  @JsonKey(
    
    name: r'app_version',
    required: false,
    includeIfNull: false,
  )


  final String? appVersion;



  @JsonKey(
    
    name: r'locale',
    required: false,
    includeIfNull: false,
  )


  final String? locale;



  @JsonKey(
    
    name: r'device_label',
    required: false,
    includeIfNull: false,
  )


  final String? deviceLabel;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PushTokenIn &&
      other.token == token &&
      other.platform == platform &&
      other.appFlavor == appFlavor &&
      other.appVersion == appVersion &&
      other.locale == locale &&
      other.deviceLabel == deviceLabel;

    @override
    int get hashCode =>
        token.hashCode +
        platform.hashCode +
        (appFlavor == null ? 0 : appFlavor.hashCode) +
        (appVersion == null ? 0 : appVersion.hashCode) +
        (locale == null ? 0 : locale.hashCode) +
        (deviceLabel == null ? 0 : deviceLabel.hashCode);

  factory PushTokenIn.fromJson(Map<String, dynamic> json) => _$PushTokenInFromJson(json);

  Map<String, dynamic> toJson() => _$PushTokenInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

