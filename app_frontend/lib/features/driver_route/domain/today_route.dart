import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/driver_route/domain/asset_summary.dart';
import 'package:hawa_app/features/driver_route/domain/shift.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';

part 'today_route.freezed.dart';

/// Route header + ordered stops + asset + shift window for one IST service date.
@freezed
abstract class TodayRoute with _$TodayRoute {
  const factory TodayRoute({
    required String date,
    required String routeId,
    required int version,
    required List<Stop> stops,
    required DateTime fetchedAt,
    AssetSummary? asset,
    Shift? shift,
    @Default(<GeoPoint>[]) List<GeoPoint> geometry,
    GeoBox? bbox,
    @Default(false) bool isSimulated,
  }) = _TodayRoute;

  const TodayRoute._();

  /// Stops still on the route (removed stops are listed, but not counted).
  List<Stop> get activeStops => stops.where((s) => s.shownStatus != TaskStatus.cancelled).toList();

  /// The first open stop in sequence order: the hero card.
  Stop? get nextStop {
    for (final s in stops) {
      if (s.isOpen) return s;
    }
    return null;
  }

  bool get allDone => stops.isNotEmpty && nextStop == null;

  bool get hasSimulated =>
      isSimulated || (asset?.isSimulated ?? false) || stops.any((s) => s.isSimulated);

  int get doneCount => stops.where((s) => s.shownStatus.isCompleted).length;

  int get skippedCount => stops.where((s) => s.shownStatus == TaskStatus.skipped).length;

  int get pendingCount => stops.where((s) => s.isOpen).length;

  int get verifiedCount => stops.where((s) => s.status == TaskStatus.verified).length;

  /// Litres confirmed by HawaTag (manual entries are not added here).
  double get tagLitres =>
      stops.where((s) => s.doneByTag).fold(0, (sum, s) => sum + (s.litres ?? 0));

  Stop? stop(String taskId) {
    for (final s in stops) {
      if (s.taskId == taskId) return s;
    }
    return null;
  }

  int positionOf(String taskId) => activeStops.indexWhere((s) => s.taskId == taskId) + 1;
}
