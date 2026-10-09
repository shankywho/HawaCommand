//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'localized_text.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocalizedText {
  /// Returns a new [LocalizedText] instance.
  LocalizedText({

    required  this.en,

     this.hi,
  });

  @JsonKey(
    
    name: r'en',
    required: true,
    includeIfNull: false,
  )


  final String en;



  @JsonKey(
    
    name: r'hi',
    required: false,
    includeIfNull: false,
  )


  final String? hi;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocalizedText &&
      other.en == en &&
      other.hi == hi;

    @override
    int get hashCode =>
        en.hashCode +
        (hi == null ? 0 : hi.hashCode);

  factory LocalizedText.fromJson(Map<String, dynamic> json) => _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

