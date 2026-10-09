//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/location_ping.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_batch_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LocationBatchIn {
  /// Returns a new [LocationBatchIn] instance.
  LocationBatchIn({

    required  this.pings,
  });

  @JsonKey(
    
    name: r'pings',
    required: true,
    includeIfNull: false,
  )


  final List<LocationPing> pings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LocationBatchIn &&
      other.pings == pings;

    @override
    int get hashCode =>
        pings.hashCode;

  factory LocationBatchIn.fromJson(Map<String, dynamic> json) => _$LocationBatchInFromJson(json);

  Map<String, dynamic> toJson() => _$LocationBatchInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

