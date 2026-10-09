//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum AssetType {
      @JsonValue(r'sprinkler')
      sprinkler(r'sprinkler'),
      @JsonValue(r'anti_smog_gun')
      antiSmogGun(r'anti_smog_gun'),
      @JsonValue(r'sweeper')
      sweeper(r'sweeper'),
      @JsonValue(r'inspection_team')
      inspectionTeam(r'inspection_team'),
      @JsonValue(r'unknown_default_open_api')
      unknownDefaultOpenApi(r'unknown_default_open_api');

  const AssetType(this.value);

  final String value;

  @override
  String toString() => value;
}
