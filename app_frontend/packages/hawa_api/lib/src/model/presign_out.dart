//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'presign_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PresignOut {
  /// Returns a new [PresignOut] instance.
  PresignOut({

    required  this.key,

    required  this.url,

    required  this.method,

    required  this.expiresAt,

     this.fields,

     this.headers,

     this.maxBytes,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'method',
    required: true,
    includeIfNull: false,
  )


  final String method;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'fields',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? fields;



  @JsonKey(
    
    name: r'headers',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? headers;



  @JsonKey(
    
    name: r'max_bytes',
    required: false,
    includeIfNull: false,
  )


  final int? maxBytes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PresignOut &&
      other.key == key &&
      other.url == url &&
      other.method == method &&
      other.expiresAt == expiresAt &&
      other.fields == fields &&
      other.headers == headers &&
      other.maxBytes == maxBytes;

    @override
    int get hashCode =>
        key.hashCode +
        url.hashCode +
        method.hashCode +
        expiresAt.hashCode +
        (fields == null ? 0 : fields.hashCode) +
        (headers == null ? 0 : headers.hashCode) +
        (maxBytes == null ? 0 : maxBytes.hashCode);

  factory PresignOut.fromJson(Map<String, dynamic> json) => _$PresignOutFromJson(json);

  Map<String, dynamic> toJson() => _$PresignOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

