//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/lang.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me_patch_in.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MePatchIn {
  /// Returns a new [MePatchIn] instance.
  MePatchIn({

     this.lang,

     this.notificationPrefs,
  });

  @JsonKey(
    
    name: r'lang',
    required: false,
    includeIfNull: false,
  unknownEnumValue: Lang.unknownDefaultOpenApi,
  )


  final Lang? lang;



  @JsonKey(
    
    name: r'notification_prefs',
    required: false,
    includeIfNull: false,
  )


  final Map<String, bool>? notificationPrefs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MePatchIn &&
      other.lang == lang &&
      other.notificationPrefs == notificationPrefs;

    @override
    int get hashCode =>
        lang.hashCode +
        (notificationPrefs == null ? 0 : notificationPrefs.hashCode);

  factory MePatchIn.fromJson(Map<String, dynamic> json) => _$MePatchInFromJson(json);

  Map<String, dynamic> toJson() => _$MePatchInToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

