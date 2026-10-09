//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'licence.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Licence {
  /// Returns a new [Licence] instance.
  Licence({

     this.data,

     this.osm,

     this.attribution,
  });

  @JsonKey(
    
    name: r'data',
    required: false,
    includeIfNull: false,
  )


  final String? data;



  @JsonKey(
    
    name: r'osm',
    required: false,
    includeIfNull: false,
  )


  final String? osm;



  @JsonKey(
    
    name: r'attribution',
    required: false,
    includeIfNull: false,
  )


  final String? attribution;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Licence &&
      other.data == data &&
      other.osm == osm &&
      other.attribution == attribution;

    @override
    int get hashCode =>
        (data == null ? 0 : data.hashCode) +
        (osm == null ? 0 : osm.hashCode) +
        (attribution == null ? 0 : attribution.hashCode);

  factory Licence.fromJson(Map<String, dynamic> json) => _$LicenceFromJson(json);

  Map<String, dynamic> toJson() => _$LicenceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

