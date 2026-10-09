//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'site_ref.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteRef {
  /// Returns a new [SiteRef] instance.
  SiteRef({

    required  this.siteId,

    required  this.name,
  });

  @JsonKey(
    
    name: r'site_id',
    required: true,
    includeIfNull: false,
  )


  final String siteId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteRef &&
      other.siteId == siteId &&
      other.name == name;

    @override
    int get hashCode =>
        siteId.hashCode +
        name.hashCode;

  factory SiteRef.fromJson(Map<String, dynamic> json) => _$SiteRefFromJson(json);

  Map<String, dynamic> toJson() => _$SiteRefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

