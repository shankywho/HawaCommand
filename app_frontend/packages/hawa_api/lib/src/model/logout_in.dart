//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'logout_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LogoutIn {
  /// Returns a new [LogoutIn] instance.
  LogoutIn({

    required  this.refreshToken,

     this.allDevices,
  });

  @JsonKey(
    
    name: r'refresh_token',
    required: true,
    includeIfNull: false,
  )


  final String refreshToken;



  @JsonKey(
    
    name: r'all_devices',
    required: false,
    includeIfNull: false,
  )


  final bool? allDevices;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LogoutIn &&
      other.refreshToken == refreshToken &&
      other.allDevices == allDevices;

    @override
    int get hashCode =>
        refreshToken.hashCode +
        (allDevices == null ? 0 : allDevices.hashCode);

  factory LogoutIn.fromJson(Map<String, dynamic> json) => _$LogoutInFromJson(json);

  Map<String, dynamic> toJson() => _$LogoutInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

