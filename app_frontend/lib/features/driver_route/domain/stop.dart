import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/features/driver_route/domain/impact_summary.dart';

part 'stop.freezed.dart';
part 'stop.g.dart';

/// One stop on today's route (ARCHITECTURE §8). Times are UTC; the UI formats them in IST.
@freezed
abstract class Stop with _$Stop {
  const factory Stop({
    required String taskId,
    required int sequence,
    required TaskKind kind,

    /// Server status (authoritative).
    required TaskStatus status,
    required GeoPoint location,
    required LocalizedText placeName,
    required DateTime windowStart,
    required DateTime windowEnd,
    required bool isSimulated,

    /// Optimistic status from an unsent outbox op (shown with a small clock icon).
    TaskStatus? pendingStatus,
    String? planId,
    String? cellId,
    LocalizedText? instructions,
    LocalizedText? reasonText,
    double? targetLitres,
    double? segmentLengthM,
    int? durationMin,
    @Default(150) double arrivalRadiusM,
    CauseLabel? causeLabel,
    double? causeConf,
    InterventionSource? completionSource,

    /// Litres recorded for the stop (HawaTag or the manual entry).
    double? litres,
    ImpactSummary? impact,
    String? skipReason,
    @Default(0) int version,

    /// Local-only "I've arrived" (geofence or button); never sent for drivers.
    DateTime? arrivedAt,
  }) = _Stop;

  const Stop._();

  factory Stop.fromJson(Map<String, Object?> json) => _$StopFromJson(json);

  /// Status to show: the overlay only while the server status is not terminal (§7).
  TaskStatus get shownStatus =>
      pendingStatus != null && !status.isTerminal ? pendingStatus! : status;

  bool get hasPendingOp => pendingStatus != null && !status.isTerminal;

  bool get isOpen => shownStatus.isOpen;

  bool get doneByTag => status.isCompleted && completionSource == InterventionSource.hawatag;

  /// Manual or naive evidence is labelled "lower evidence".
  bool get lowerEvidence =>
      completionSource == InterventionSource.manual ||
      (pendingStatus == TaskStatus.done && !status.isTerminal) ||
      (impact?.method.isLowerEvidence ?? false);
}
