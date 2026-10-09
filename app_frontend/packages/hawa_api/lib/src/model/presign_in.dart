//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/upload_purpose.dart';
import 'package:json_annotation/json_annotation.dart';

part 'presign_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PresignIn {
  /// Returns a new [PresignIn] instance.
  PresignIn({

    required  this.purpose,

    required  this.contentType,

    required  this.contentLength,

    required  this.sha256,
  });

  @JsonKey(
    
    name: r'purpose',
    required: true,
    includeIfNull: false,
  unknownEnumValue: UploadPurpose.unknownDefaultOpenApi,
  )


  final UploadPurpose purpose;



  @JsonKey(
    
    name: r'content_type',
    required: true,
    includeIfNull: false,
  )


  final String contentType;



  @JsonKey(
    
    name: r'content_length',
    required: true,
    includeIfNull: false,
  )


  final int contentLength;



  @JsonKey(
    
    name: r'sha256',
    required: true,
    includeIfNull: false,
  )


  final String sha256;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PresignIn &&
      other.purpose == purpose &&
      other.contentType == contentType &&
      other.contentLength == contentLength &&
      other.sha256 == sha256;

    @override
    int get hashCode =>
        purpose.hashCode +
        contentType.hashCode +
        contentLength.hashCode +
        sha256.hashCode;

  factory PresignIn.fromJson(Map<String, dynamic> json) => _$PresignInFromJson(json);

  Map<String, dynamic> toJson() => _$PresignInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

