//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/report_list_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_page.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportPage {
  /// Returns a new [ReportPage] instance.
  ReportPage({

    required  this.items,

     this.nextCursor,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ReportListItem> items;



  @JsonKey(
    
    name: r'next_cursor',
    required: false,
    includeIfNull: false,
  )


  final String? nextCursor;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportPage &&
      other.items == items &&
      other.nextCursor == nextCursor;

    @override
    int get hashCode =>
        items.hashCode +
        (nextCursor == null ? 0 : nextCursor.hashCode);

  factory ReportPage.fromJson(Map<String, dynamic> json) => _$ReportPageFromJson(json);

  Map<String, dynamic> toJson() => _$ReportPageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

