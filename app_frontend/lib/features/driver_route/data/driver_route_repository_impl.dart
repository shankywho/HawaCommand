import 'package:drift/drift.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/media/image_processor.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/daos/outbox_dao.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/sync/conflict_resolver.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/features/driver_route/data/task_local_source.dart';
import 'package:hawa_app/features/driver_route/data/task_mapper.dart';
import 'package:hawa_app/features/driver_route/data/task_remote_source.dart';
import 'package:hawa_app/features/driver_route/domain/driver_route_repository.dart';
import 'package:hawa_app/features/driver_route/domain/route_diff.dart';
import 'package:hawa_app/features/driver_route/domain/shift.dart';
import 'package:hawa_app/features/driver_route/domain/skip_reason.dart';
import 'package:hawa_app/features/driver_route/domain/stop.dart';
import 'package:hawa_app/features/driver_route/domain/today_route.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'driver_route_repository_impl.g.dart';

class DriverRouteRepositoryImpl implements DriverRouteRepository {
  DriverRouteRepositoryImpl({
    required this.remote,
    required this.local,
    required this.db,
    required this.outbox,
    required this.clock,
    required this.resolver,
    required this.images,
    required this.settings,
  });

  final TaskRemoteSource remote;
  final TaskLocalSource local;
  final AppDatabase db;
  final OutboxRepository outbox;
  final Clock clock;
  final ConflictResolver resolver;
  final ImageProcessor images;
  final SettingsStore settings;

  static String scope(String date) => 'tasks:$date';

  DateTime get _now => clock.now().toUtc();

  @override
  Stream<TodayRoute?> watchRoute(String date) => local.watchRoute(date);

  /// Stale-while-revalidate (OFFLINE_AND_SYNC §4). A full snapshot replaces the day; rows with
  /// unsent ops are kept and their ops resolve through the conflict rules (§7).
  @override
  Future<RouteDiff?> refresh(String date) async {
    final now = _now;
    try {
      final res = await remote.fetchMine(date);
      final before = await local.getRoute(date);
      final stops = res.items.map(TaskMapper.stop).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      // An empty response after the shift window is not "all stops removed" (§4 exception).
      if (stops.isEmpty && before != null && before.stops.isNotEmpty) {
        await db.syncStateDao.markSuccess(scope(date), now);
        return null;
      }
      final keep = await _tasksWithUnsentOps();
      final previousIds = await local.saveSnapshot(
        date: date,
        routeId: res.route?.routeId ?? 'local:driver:$date',
        version: res.route?.version ?? 0,
        asset: res.asset == null ? null : TaskMapper.asset(res.asset!),
        shift: res.shift == null ? null : TaskMapper.shift(res.shift!),
        geometry: TaskMapper.line(res.route?.geometry),
        bbox: TaskMapper.bbox(res.route?.bbox),
        isSimulated: res.asset?.isSimulated ?? stops.any((s) => s.isSimulated),
        stops: stops,
        fetchedAt: now,
        keepIds: keep,
      );
      final newIds = {for (final s in stops) s.taskId};
      for (final removed in previousIds.difference(newIds).where(keep.contains)) {
        await resolver.onTaskRemoved(removed);
      }
      for (final s in stops.where((s) => s.status.isTerminal && keep.contains(s.taskId))) {
        await resolver.onServerTaskStatus(
          s.taskId,
          s.status.wire,
          source: s.completionSource?.wire,
        );
      }
      await db.syncStateDao.markSuccess(scope(date), now);
      if (before == null || before.stops.isEmpty) return null;
      return RouteDiff.between(
        [for (final s in before.stops) s.taskId],
        [for (final s in stops) s.taskId],
        cancelledAfter: {
          for (final s in stops)
            if (s.status == TaskStatus.cancelled) s.taskId,
        },
      );
    } on Failure catch (f) {
      await db.syncStateDao.markAttempt(
        scope(date),
        now,
        errorCode: f.code ?? f.runtimeType.toString(),
      );
      rethrow;
    }
  }

  Future<Set<String>> _tasksWithUnsentOps() async {
    final rows =
        await (db.select(db.outboxOpsTable)..where(
              (o) =>
                  o.orderingKey.like('task:%') &
                  o.state.isIn(const [OutboxDao.pending, OutboxDao.inFlight]),
            ))
            .get();
    return {for (final r in rows) r.orderingKey.substring('task:'.length)};
  }

  @override
  Future<void> acknowledgeDispatched(TodayRoute route) async {
    for (final s in route.stops.where(
      (s) => s.status == TaskStatus.dispatched && s.pendingStatus == null,
    )) {
      await outbox.enqueue(
        kind: OpKind.taskAck,
        orderingKey: OrderingKeys.task(s.taskId),
        payload: {'task_id': s.taskId, 'at': _now.toIso8601String()},
        dedupe: true,
      );
    }
  }

  @override
  Future<void> markEnRoute(Stop stop) async {
    if (!const {TaskStatus.dispatched, TaskStatus.acknowledged}.contains(stop.shownStatus)) return;
    await _statusOp(stop.taskId, TaskStatus.enRoute, {'status': 'en_route'});
  }

  @override
  Future<void> markArrived(String taskId, {required DateTime at}) =>
      local.setArrived(taskId, at.toUtc());

  @override
  Future<void> skip(Stop stop, SkipReason reason, {String? note}) async {
    if (!stop.shownStatus.canSkip) return;
    await _statusOp(stop.taskId, TaskStatus.skipped, {
      'status': 'skipped',
      'reason': reason.wire,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }

  @override
  Future<void> manualDone(
    Stop stop, {
    double? litres,
    String? photoPath,
    GeoPoint? location,
  }) async {
    String? photoOp;
    String? mediaId;
    if (photoPath != null) {
      final processed = await images.process(photoPath, dataSaver: settings.dataSaver);
      mediaId = processed.id;
      await db.mediaDao.insertMedia(
        MediaFilesTableCompanion.insert(
          id: processed.id,
          path: processed.file.path,
          sha256: processed.sha256,
          bytes: processed.bytes,
          purpose: 'task_photo',
          state: 'local',
          createdAt: _now,
          thumbPath: Value(processed.thumb?.path),
        ),
      );
      photoOp = await outbox.enqueue(
        kind: OpKind.photoUpload,
        orderingKey: OrderingKeys.media(processed.id),
        payload: {'media_id': processed.id},
      );
    }
    await _statusOp(
      stop.taskId,
      TaskStatus.done,
      {
        'status': 'done',
        'source': 'manual',
        'litres': ?litres,
        if (mediaId != null) 'media_ids': [mediaId],
        if (location != null) 'location': {'lat': location.lat, 'lon': location.lon},
      },
      dependsOn: photoOp,
    );
  }

  /// Optimistic overlay + op in one transaction, so UI and queue never disagree (§5.1).
  Future<void> _statusOp(
    String taskId,
    TaskStatus overlay,
    Map<String, Object?> body, {
    String? dependsOn,
  }) => db.transaction(() async {
    await db.taskDao.setPendingStatus(taskId, overlay.wire);
    await outbox.enqueue(
      kind: OpKind.taskStatus,
      orderingKey: OrderingKeys.task(taskId),
      payload: {'task_id': taskId, 'client_ts': _now.toIso8601String(), ...body},
      dependsOn: dependsOn,
    );
  });

  @override
  Future<void> startShift(Shift shift, {GeoPoint? location}) async {
    await outbox.enqueue(
      kind: OpKind.shiftStart,
      orderingKey: OrderingKeys.shift(shift.id),
      payload: {
        'shift_id': shift.id,
        'at': _now.toIso8601String(),
        if (location != null) 'location': {'lat': location.lat, 'lon': location.lon},
      },
    );
  }

  @override
  Future<void> endShift(Shift shift) async {
    await outbox.enqueue(
      kind: OpKind.shiftEnd,
      orderingKey: OrderingKeys.shift(shift.id),
      payload: {'shift_id': shift.id, 'at': _now.toIso8601String()},
    );
  }
}

@Riverpod(keepAlive: true)
TaskLocalSource taskLocalSource(Ref ref) => TaskLocalSource(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
DriverRouteRepository driverRouteRepository(Ref ref) => DriverRouteRepositoryImpl(
  remote: ref.watch(taskRemoteSourceProvider),
  local: ref.watch(taskLocalSourceProvider),
  db: ref.watch(appDatabaseProvider),
  outbox: ref.watch(outboxRepositoryProvider),
  clock: ref.watch(appClockProvider),
  resolver: ref.watch(conflictResolverProvider),
  images: ref.watch(imageProcessorProvider),
  settings: ref.watch(settingsStoreProvider),
);
