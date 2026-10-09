//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'evidence_photo.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EvidencePhoto {
  /// Returns a new [EvidencePhoto] instance.
  EvidencePhoto({

    required  this.url,

    required  this.capturedAt,

     this.thumbUrl,

     this.expiresAt,
  });

  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'captured_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime capturedAt;



  @JsonKey(
    
    name: r'thumb_url',
    required: false,
    includeIfNull: false,
  )


  final String? thumbUrl;



  @JsonKey(
    
    name: r'expires_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EvidencePhoto &&
      other.url == url &&
      other.capturedAt == capturedAt &&
      other.thumbUrl == thumbUrl &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        url.hashCode +
        capturedAt.hashCode +
        (thumbUrl == null ? 0 : thumbUrl.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode);

  factory EvidencePhoto.fromJson(Map<String, dynamic> json) => _$EvidencePhotoFromJson(json);

  Map<String, dynamic> toJson() => _$EvidencePhotoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

