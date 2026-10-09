//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/alert_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'alert_page.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AlertPage {
  /// Returns a new [AlertPage] instance.
  AlertPage({

    required  this.items,

     this.nextCursor,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<AlertItem> items;



  @JsonKey(
    
    name: r'next_cursor',
    required: false,
    includeIfNull: false,
  )


  final String? nextCursor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AlertPage &&
      other.items == items &&
      other.nextCursor == nextCursor;

    @override
    int get hashCode =>
        items.hashCode +
        (nextCursor == null ? 0 : nextCursor.hashCode);

  factory AlertPage.fromJson(Map<String, dynamic> json) => _$AlertPageFromJson(json);

  Map<String, dynamic> toJson() => _$AlertPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

