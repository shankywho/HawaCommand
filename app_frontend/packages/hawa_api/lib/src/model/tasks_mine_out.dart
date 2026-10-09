//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:hawa_api/src/model/task_route.dart';
import 'package:hawa_api/src/model/task_shift.dart';
import 'package:hawa_api/src/model/task_asset.dart';
import 'package:hawa_api/src/model/user_role.dart';
import 'package:hawa_api/src/model/task_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tasks_mine_out.g.dart';


@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TasksMineOut {
  /// Returns a new [TasksMineOut] instance.
  TasksMineOut({

    required  this.date,

    required  this.items,

     this.role,

     this.asset,

     this.shift,

     this.route,

     this.serverTime,
  });

  @JsonKey(
    
    name: r'date',
    required: true,
    includeIfNull: false,
  )


  final DateTime date;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<TaskItem> items;



  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  unknownEnumValue: UserRole.unknownDefaultOpenApi,
  )


  final UserRole? role;



  @JsonKey(
    
    name: r'asset',
    required: false,
    includeIfNull: false,
  )


  final TaskAsset? asset;



  @JsonKey(
    
    name: r'shift',
    required: false,
    includeIfNull: false,
  )


  final TaskShift? shift;



  @JsonKey(
    
    name: r'route',
    required: false,
    includeIfNull: false,
  )


  final TaskRoute? route;



  @JsonKey(
    
    name: r'server_time',
    required: false,
    includeIfNull: false,
  )


  final DateTime? serverTime;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TasksMineOut &&
      other.date == date &&
      other.items == items &&
      other.role == role &&
      other.asset == asset &&
      other.shift == shift &&
      other.route == route &&
      other.serverTime == serverTime;

    @override
    int get hashCode =>
        date.hashCode +
        items.hashCode +
        role.hashCode +
        asset.hashCode +
        shift.hashCode +
        route.hashCode +
        (serverTime == null ? 0 : serverTime.hashCode);

  factory TasksMineOut.fromJson(Map<String, dynamic> json) => _$TasksMineOutFromJson(json);

  Map<String, dynamic> toJson() => _$TasksMineOutToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

