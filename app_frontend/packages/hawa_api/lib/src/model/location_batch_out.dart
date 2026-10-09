//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'location_batch_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocationBatchOut {
  /// Returns a new [LocationBatchOut] instance.
  LocationBatchOut({

    required  this.accepted,
  });

  @JsonKey(
    
    name: r'accepted',
    required: true,
    includeIfNull: false,
  )


  final int accepted;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocationBatchOut &&
      other.accepted == accepted;

    @override
    int get hashCode =>
        accepted.hashCode;

  factory LocationBatchOut.fromJson(Map<String, dynamic> json) => _$LocationBatchOutFromJson(json);

  Map<String, dynamic> toJson() => _$LocationBatchOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

