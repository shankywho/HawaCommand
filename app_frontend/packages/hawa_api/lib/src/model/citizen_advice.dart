//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:json_annotation/json_annotation.dart';

part 'citizen_advice.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CitizenAdvice {
  /// Returns a new [CitizenAdvice] instance.
  CitizenAdvice({

     this.altRoute,
  });

  @JsonKey(
    
    name: r'alt_route',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? altRoute;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CitizenAdvice &&
      other.altRoute == altRoute;

    @override
    int get hashCode =>
        altRoute.hashCode;

  factory CitizenAdvice.fromJson(Map<String, dynamic> json) => _$CitizenAdviceFromJson(json);

  Map<String, dynamic> toJson() => _$CitizenAdviceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

