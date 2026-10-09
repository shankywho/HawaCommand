//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'me_features.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MeFeatures {
  /// Returns a new [MeFeatures] instance.
  MeFeatures({

     this.citizenEyes,

     this.schoolScheduler,

     this.openData,
  });

  @JsonKey(
    
    name: r'citizen_eyes',
    required: false,
    includeIfNull: false,
  )


  final bool? citizenEyes;



  @JsonKey(
    
    name: r'school_scheduler',
    required: false,
    includeIfNull: false,
  )


  final bool? schoolScheduler;



  @JsonKey(
    
    name: r'open_data',
    required: false,
    includeIfNull: false,
  )


  final bool? openData;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MeFeatures &&
      other.citizenEyes == citizenEyes &&
      other.schoolScheduler == schoolScheduler &&
      other.openData == openData;

    @override
    int get hashCode =>
        (citizenEyes == null ? 0 : citizenEyes.hashCode) +
        (schoolScheduler == null ? 0 : schoolScheduler.hashCode) +
        (openData == null ? 0 : openData.hashCode);

  factory MeFeatures.fromJson(Map<String, dynamic> json) => _$MeFeaturesFromJson(json);

  Map<String, dynamic> toJson() => _$MeFeaturesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

