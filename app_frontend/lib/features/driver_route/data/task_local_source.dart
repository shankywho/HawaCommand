import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/streams.dart';
import 'package:hawa_app/features/driver_route/data/task_mapper.dart';
import 'package:hawa_app/features/driver_route/domain/asset_summary.dart';
import 'package:hawa_app/features/driver_route/domain/shift.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';

/// drift ↔ driver domain. A stop's full entity lives in `tasks.payload_json`; the server status,
/// optimistic overlay and local arrival live in their own columns (OFFLINE_AND_SYNC §3).
class TaskLocalSource {
  TaskLocalSource(this.db);

  final AppDatabase db;
  static const role = 'driver';

  Stream<TodayRoute?> watchRoute(String date) => combineLatest2(
    db.taskDao.watchRoute(role, date),
    db.taskDao.watchTasks(role, date),
    _toRoute,
  );

  Future<TodayRoute?> getRoute(String date) async =>
      _toRoute(await db.taskDao.getRoute(role, date), await db.taskDao.tasksFor(role, date));

  Stream<Stop?> watchStop(String taskId) =>
      db.taskDao.watchTask(taskId).map((r) => r == null ? null : _toStop(r));

  Future<Stop?> getStop(String taskId) async {
    final row = await db.taskDao.getTask(taskId);
    return row == null ? null : _toStop(row);
  }

  /// Replaces the day (server wins); returns the previous task ids.
  Future<Set<String>> saveSnapshot({
    required String date,
    required String routeId,
    required int version,
    required AssetSummary? asset,
    required Shift? shift,
    required List<GeoPoint> geometry,
    required GeoBox? bbox,
    required bool isSimulated,
    required List<Stop> stops,
    required DateTime fetchedAt,
    Set<String> keepIds = const {},
  }) => db.taskDao.replaceSnapshot(
    role: role,
    date: date,
    keepIds: keepIds,
    route: RoutesTableCompanion.insert(
      routeId: routeId,
      role: role,
      serviceDate: date,
      assetJson: Value(asset == null ? null : jsonEncode(asset.toJson())),
      shiftJson: Value(shift == null ? null : jsonEncode(shift.toJson())),
      geometryJson: Value(jsonEncode([for (final p in geometry) p.toLonLat()])),
      bboxJson: Value(bbox == null ? null : jsonEncode(bbox.toJson())),
      version: Value(version),
      isSimulated: Value(isSimulated),
      fetchedAt: fetchedAt,
    ),
    tasks: [
      for (final s in stops) companion(s, date: date, routeId: routeId, fetchedAt: fetchedAt),
    ],
  );

  static TasksTableCompanion companion(
    Stop s, {
    required String date,
    required String? routeId,
    required DateTime fetchedAt,
  }) => TasksTableCompanion.insert(
    id: s.taskId,
    routeId: Value(routeId),
    role: const Value(role),
    kind: s.kind.wire,
    status: s.status.wire,
    completionSource: Value(s.completionSource?.wire),
    serviceDate: date,
    sequence: Value(s.sequence),
    windowStart: s.windowStart,
    windowEnd: s.windowEnd,
    lat: s.location.lat,
    lon: s.location.lon,
    payloadJson: jsonEncode(s.copyWith(pendingStatus: null, arrivedAt: null).toJson()),
    serverVersion: Value(s.version),
    serverUpdatedAt: fetchedAt,
    isSimulated: Value(s.isSimulated),
  );

  /// Server-confirmed change for one stop (WS event or op response), merged into the payload.
  Future<void> applyServer(
    String taskId, {
    required String status,
    String? source,
    double? litres,
    Map<String, Object?>? impactJson,
    int? version,
    DateTime? at,
  }) async {
    final row = await db.taskDao.getTask(taskId);
    if (row == null) return;
    final current = Stop.fromJson((jsonDecode(row.payloadJson) as Map).cast<String, Object?>());
    final updated = current.copyWith(
      status: TaskStatus.fromWire(status),
      completionSource: source == null
          ? current.completionSource
          : InterventionSource.fromWire(source),
      litres: litres ?? current.litres,
      version: version ?? current.version,
    );
    final withImpact = impactJson == null
        ? updated
        : updated.copyWith(impact: TaskMapper.impactFromJson(impactJson) ?? updated.impact);
    await db.taskDao.applyServerStatus(
      taskId,
      status: status,
      completionSource: withImpact.completionSource?.wire,
      payloadJson: jsonEncode(withImpact.toJson()),
      version: version,
      updatedAt: at,
    );
  }

  Future<void> setArrived(String taskId, DateTime? at) => db.taskDao.setArrived(taskId, at);

  static Stop _toStop(TaskRow r) {
    final s = Stop.fromJson((jsonDecode(r.payloadJson) as Map).cast<String, Object?>());
    return s.copyWith(
      status: TaskStatus.fromWire(r.status),
      pendingStatus: r.pendingStatus == null ? null : TaskStatus.fromWire(r.pendingStatus),
      completionSource: r.completionSource == null
          ? s.completionSource
          : InterventionSource.fromWire(r.completionSource),
      arrivedAt: r.arrivedAt,
    );
  }

  static TodayRoute? _toRoute(RouteRow? route, List<TaskRow> tasks) {
    if (route == null) return null;
    final geometry = route.geometryJson == null
        ? const <GeoPoint>[]
        : [
            for (final c in jsonDecode(route.geometryJson!) as List)
              GeoPoint.fromLonLat([for (final v in c as List) (v as num).toDouble()]),
          ];
    return TodayRoute(
      date: route.serviceDate,
      routeId: route.routeId,
      version: route.version,
      stops: [for (final t in tasks) _toStop(t)],
      fetchedAt: route.fetchedAt,
      asset: route.assetJson == null
          ? null
          : AssetSummary.fromJson((jsonDecode(route.assetJson!) as Map).cast<String, Object?>()),
      shift: route.shiftJson == null
          ? null
          : Shift.fromJson((jsonDecode(route.shiftJson!) as Map).cast<String, Object?>()),
      geometry: geometry,
      bbox: route.bboxJson == null
          ? null
          : GeoBox.fromJson((jsonDecode(route.bboxJson!) as Map).cast<String, Object?>()),
      isSimulated: route.isSimulated,
    );
  }
}
