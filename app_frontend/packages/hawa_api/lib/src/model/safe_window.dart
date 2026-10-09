//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/safe_window_label.dart';
import 'package:json_annotation/json_annotation.dart';

part 'safe_window.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SafeWindow {
  /// Returns a new [SafeWindow] instance.
  SafeWindow({

    required  this.start,

    required  this.end,

    required  this.label,

     this.pm25P10,

     this.pm25P50,

     this.pm25P90,

     this.confidence,
  });

  @JsonKey(
    
    name: r'start',
    required: true,
    includeIfNull: false,
  )


  final DateTime start;



  @JsonKey(
    
    name: r'end',
    required: true,
    includeIfNull: false,
  )


  final DateTime end;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  unknownEnumValue: SafeWindowLabel.unknownDefaultOpenApi,
  )


  final SafeWindowLabel label;



  @JsonKey(
    
    name: r'pm25_p10',
    required: false,
    includeIfNull: false,
  )


  final double? pm25P10;



  @JsonKey(
    
    name: r'pm25_p50',
    required: false,
    includeIfNull: false,
  )


  final double? pm25P50;



  @JsonKey(
    
    name: r'pm25_p90',
    required: false,
    includeIfNull: false,
  )


  final double? pm25P90;



  @JsonKey(
    
    name: r'confidence',
    required: false,
    includeIfNull: false,
  )


  final double? confidence;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SafeWindow &&
      other.start == start &&
      other.end == end &&
      other.label == label &&
      other.pm25P10 == pm25P10 &&
      other.pm25P50 == pm25P50 &&
      other.pm25P90 == pm25P90 &&
      other.confidence == confidence;

    @override
    int get hashCode =>
        start.hashCode +
        end.hashCode +
        label.hashCode +
        (pm25P10 == null ? 0 : pm25P10.hashCode) +
        (pm25P50 == null ? 0 : pm25P50.hashCode) +
        (pm25P90 == null ? 0 : pm25P90.hashCode) +
        (confidence == null ? 0 : confidence.hashCode);

  factory SafeWindow.fromJson(Map<String, dynamic> json) => _$SafeWindowFromJson(json);

  Map<String, dynamic> toJson() => _$SafeWindowToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

