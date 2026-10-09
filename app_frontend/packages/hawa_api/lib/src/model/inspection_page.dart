//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/inspection_list_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inspection_page.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InspectionPage {
  /// Returns a new [InspectionPage] instance.
  InspectionPage({

    required  this.items,

     this.nextCursor,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<InspectionListItem> items;



  @JsonKey(
    
    name: r'next_cursor',
    required: false,
    includeIfNull: false,
  )


  final String? nextCursor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InspectionPage &&
      other.items == items &&
      other.nextCursor == nextCursor;

    @override
    int get hashCode =>
        items.hashCode +
        (nextCursor == null ? 0 : nextCursor.hashCode);

  factory InspectionPage.fromJson(Map<String, dynamic> json) => _$InspectionPageFromJson(json);

  Map<String, dynamic> toJson() => _$InspectionPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

