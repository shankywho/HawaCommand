//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/alert_kind.dart';
import 'package:hawa_api/src/model/lat_lon.dart';
import 'package:hawa_api/src/model/localized_text.dart';
import 'package:hawa_api/src/model/quiet_hours.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alert_subscription.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlertSubscription {
  /// Returns a new [AlertSubscription] instance.
  AlertSubscription({

    required  this.radiusM,

    required  this.kinds,

     this.home,

     this.placeName,

     this.quietHours,
  });

  @JsonKey(
    
    name: r'radius_m',
    required: true,
    includeIfNull: false,
  )


  final int radiusM;



  @JsonKey(
    
    name: r'kinds',
    required: true,
    includeIfNull: false,
  )


  final List<AlertKind> kinds;



  @JsonKey(
    
    name: r'home',
    required: false,
    includeIfNull: false,
  )


  final LatLon? home;



  @JsonKey(
    
    name: r'place_name',
    required: false,
    includeIfNull: false,
  )


  final LocalizedText? placeName;



  @JsonKey(
    
    name: r'quiet_hours',
    required: false,
    includeIfNull: false,
  )


  final QuietHours? quietHours;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlertSubscription &&
      other.radiusM == radiusM &&
      other.kinds == kinds &&
      other.home == home &&
      other.placeName == placeName &&
      other.quietHours == quietHours;

    @override
    int get hashCode =>
        radiusM.hashCode +
        kinds.hashCode +
        home.hashCode +
        placeName.hashCode +
        quietHours.hashCode;

  factory AlertSubscription.fromJson(Map<String, dynamic> json) => _$AlertSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$AlertSubscriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

