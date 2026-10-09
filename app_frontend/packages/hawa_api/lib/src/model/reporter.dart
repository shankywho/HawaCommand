//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';

part 'reporter.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Reporter {
  /// Returns a new [Reporter] instance.
  Reporter({

    required  this.kind,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Reporter &&
      other.kind == kind;

    @override
    int get hashCode =>
        kind.hashCode;

  factory Reporter.fromJson(Map<String, dynamic> json) => _$ReporterFromJson(json);

  Map<String, dynamic> toJson() => _$ReporterToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

