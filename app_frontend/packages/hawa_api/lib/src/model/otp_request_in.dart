//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/otp_channel.dart';
import 'package:json_annotation/json_annotation.dart';

part 'otp_request_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OtpRequestIn {
  /// Returns a new [OtpRequestIn] instance.
  OtpRequestIn({

    required  this.phoneE164,

    required  this.channel,

    required  this.lang,

     this.appSignature,
  });

  @JsonKey(
    
    name: r'phone_e164',
    required: true,
    includeIfNull: false,
  )


  final String phoneE164;



  @JsonKey(
    
    name: r'channel',
    required: true,
    includeIfNull: false,
  unknownEnumValue: OtpChannel.unknownDefaultOpenApi,
  )


  final OtpChannel channel;



  @JsonKey(
    
    name: r'lang',
    required: true,
    includeIfNull: false,
  unknownEnumValue: Lang.unknownDefaultOpenApi,
  )


  final Lang lang;



  @JsonKey(
    
    name: r'app_signature',
    required: false,
    includeIfNull: false,
  )


  final String? appSignature;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OtpRequestIn &&
      other.phoneE164 == phoneE164 &&
      other.channel == channel &&
      other.lang == lang &&
      other.appSignature == appSignature;

    @override
    int get hashCode =>
        phoneE164.hashCode +
        channel.hashCode +
        lang.hashCode +
        (appSignature == null ? 0 : appSignature.hashCode);

  factory OtpRequestIn.fromJson(Map<String, dynamic> json) => _$OtpRequestInFromJson(json);

  Map<String, dynamic> toJson() => _$OtpRequestInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

