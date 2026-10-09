//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'otp_verify_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OtpVerifyIn {
  /// Returns a new [OtpVerifyIn] instance.
  OtpVerifyIn({

    required  this.phoneE164,

    required  this.code,

     this.requestId,

     this.deviceLabel,

     this.installId,
  });

  @JsonKey(
    
    name: r'phone_e164',
    required: true,
    includeIfNull: false,
  )


  final String phoneE164;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'request_id',
    required: false,
    includeIfNull: false,
  )


  final String? requestId;



  @JsonKey(
    
    name: r'device_label',
    required: false,
    includeIfNull: false,
  )


  final String? deviceLabel;



  @JsonKey(
    
    name: r'install_id',
    required: false,
    includeIfNull: false,
  )


  final String? installId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OtpVerifyIn &&
      other.phoneE164 == phoneE164 &&
      other.code == code &&
      other.requestId == requestId &&
      other.deviceLabel == deviceLabel &&
      other.installId == installId;

    @override
    int get hashCode =>
        phoneE164.hashCode +
        code.hashCode +
        (requestId == null ? 0 : requestId.hashCode) +
        (deviceLabel == null ? 0 : deviceLabel.hashCode) +
        (installId == null ? 0 : installId.hashCode);

  factory OtpVerifyIn.fromJson(Map<String, dynamic> json) => _$OtpVerifyInFromJson(json);

  Map<String, dynamic> toJson() => _$OtpVerifyInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

