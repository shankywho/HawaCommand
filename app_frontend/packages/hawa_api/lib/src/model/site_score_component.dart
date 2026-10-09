//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_score_component.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteScoreComponent {
  /// Returns a new [SiteScoreComponent] instance.
  SiteScoreComponent({

    required  this.name,

    required  this.value,

     this.label,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final double value;



  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? label;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteScoreComponent &&
      other.name == name &&
      other.value == value &&
      other.label == label;

    @override
    int get hashCode =>
        name.hashCode +
        value.hashCode +
        label.hashCode;

  factory SiteScoreComponent.fromJson(Map<String, dynamic> json) => _$SiteScoreComponentFromJson(json);

  Map<String, dynamic> toJson() => _$SiteScoreComponentToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

