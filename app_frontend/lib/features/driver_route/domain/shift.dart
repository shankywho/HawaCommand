import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';

part 'shift.freezed.dart';
part 'shift.g.dart';

/// The `asset_shift` from `tasks/mine.shift` (`ShiftStatus` scheduled → active → ended).
@freezed
abstract class Shift with _$Shift {
  const factory Shift({
    required String id,
    required ShiftStatus status,
    required DateTime start,
    required DateTime end,
    DateTime? startedAt,
    DateTime? endedAt,
  }) = _Shift;

  factory Shift.fromJson(Map<String, Object?> json) => _$ShiftFromJson(json);
}
