//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/school_now.dart';
import 'package:hawa_api/src/model/lang.dart';
import 'package:hawa_api/src/model/school_devices.dart';
import 'package:hawa_api/src/model/geo_point.dart';
import 'package:hawa_api/src/model/school_hours.dart';
import 'package:hawa_api/src/model/school_today.dart';
import 'package:json_annotation/json_annotation.dart';

part 'school_me_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SchoolMeOut {
  /// Returns a new [SchoolMeOut] instance.
  SchoolMeOut({

    required  this.schoolId,

    required  this.name,

    required  this.wardId,

    required  this.cellId,

    required  this.location,

    required  this.isSimulated,

     this.nameHi,

     this.forecastCellId,

     this.devices,

     this.hours,

     this.now,

     this.today,

     this.whatsappOptIn,

     this.preferredLang,
  });

  @JsonKey(
    
    name: r'school_id',
    required: true,
    includeIfNull: false,
  )


  final String schoolId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'ward_id',
    required: true,
    includeIfNull: false,
  )


  final String wardId;



  @JsonKey(
    
    name: r'cell_id',
    required: true,
    includeIfNull: false,
  )


  final String cellId;



  @JsonKey(
    
    name: r'location',
    required: true,
    includeIfNull: false,
  )


  final GeoPoint location;



  @JsonKey(
    
    name: r'is_simulated',
    required: true,
    includeIfNull: false,
  )


  final bool isSimulated;



  @JsonKey(
    
    name: r'name_hi',
    required: false,
    includeIfNull: false,
  )


  final String? nameHi;



  @JsonKey(
    
    name: r'forecast_cell_id',
    required: false,
    includeIfNull: false,
  )


  final String? forecastCellId;



  @JsonKey(
    
    name: r'devices',
    required: false,
    includeIfNull: false,
  )


  final SchoolDevices? devices;



  @JsonKey(
    
    name: r'hours',
    required: false,
    includeIfNull: false,
  )


  final SchoolHours? hours;



  @JsonKey(
    
    name: r'now',
    required: false,
    includeIfNull: false,
  )


  final SchoolNow? now;



  @JsonKey(
    
    name: r'today',
    required: false,
    includeIfNull: false,
  )


  final SchoolToday? today;



  @JsonKey(
    
    name: r'whatsapp_opt_in',
    required: false,
    includeIfNull: false,
  )


  final bool? whatsappOptIn;



  @JsonKey(
    
    name: r'preferred_lang',
    required: false,
    includeIfNull: false,
  unknownEnumValue: Lang.unknownDefaultOpenApi,
  )


  final Lang? preferredLang;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SchoolMeOut &&
      other.schoolId == schoolId &&
      other.name == name &&
      other.wardId == wardId &&
      other.cellId == cellId &&
      other.location == location &&
      other.isSimulated == isSimulated &&
      other.nameHi == nameHi &&
      other.forecastCellId == forecastCellId &&
      other.devices == devices &&
      other.hours == hours &&
      other.now == now &&
      other.today == today &&
      other.whatsappOptIn == whatsappOptIn &&
      other.preferredLang == preferredLang;

    @override
    int get hashCode =>
        schoolId.hashCode +
        name.hashCode +
        wardId.hashCode +
        cellId.hashCode +
        location.hashCode +
        isSimulated.hashCode +
        (nameHi == null ? 0 : nameHi.hashCode) +
        (forecastCellId == null ? 0 : forecastCellId.hashCode) +
        devices.hashCode +
        hours.hashCode +
        now.hashCode +
        today.hashCode +
        (whatsappOptIn == null ? 0 : whatsappOptIn.hashCode) +
        preferredLang.hashCode;

  factory SchoolMeOut.fromJson(Map<String, dynamic> json) => _$SchoolMeOutFromJson(json);

  Map<String, dynamic> toJson() => _$SchoolMeOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

