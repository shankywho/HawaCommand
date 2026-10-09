//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'otp_request_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OtpRequestOut {
  /// Returns a new [OtpRequestOut] instance.
  OtpRequestOut({

    required  this.status,

    required  this.expiresIn,

    required  this.resendAfter,

     this.requestId,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;



  @JsonKey(
    
    name: r'expires_in',
    required: true,
    includeIfNull: false,
  )


  final int expiresIn;



  @JsonKey(
    
    name: r'resend_after',
    required: true,
    includeIfNull: false,
  )


  final int resendAfter;



  @JsonKey(
    
    name: r'request_id',
    required: false,
    includeIfNull: false,
  )


  final String? requestId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OtpRequestOut &&
      other.status == status &&
      other.expiresIn == expiresIn &&
      other.resendAfter == resendAfter &&
      other.requestId == requestId;

    @override
    int get hashCode =>
        status.hashCode +
        expiresIn.hashCode +
        resendAfter.hashCode +
        (requestId == null ? 0 : requestId.hashCode);

  factory OtpRequestOut.fromJson(Map<String, dynamic> json) => _$OtpRequestOutFromJson(json);

  Map<String, dynamic> toJson() => _$OtpRequestOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

