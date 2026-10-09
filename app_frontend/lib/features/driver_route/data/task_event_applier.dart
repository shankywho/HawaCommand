import 'dart:async';

import 'package:hawa_app/core/realtime/realtime_dispatcher.dart';
import 'package:hawa_app/core/realtime/ws_message.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/conflict_resolver.dart';
import 'package:hawa_app/core/sync/sync_providers.dart';
import 'package:hawa_app/core/utils/contract_enums.dart';
import 'package:hawa_app/features/driver_route/data/driver_route_repository_impl.dart';
import 'package:hawa_app/features/driver_route/data/task_local_source.dart';
import 'package:hawa_app/features/driver_route/domain/auto_done_event.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_event_applier.g.dart';

/// WS / push `task.*` → drift upsert (server wins) + conflict resolution (ARCHITECTURE §10.1).
/// `task.done` with `source=hawatag` emits an [AutoDoneEvent]; `task.cancelled` /
/// `task.updated` signal a route change (refetch + banner).
class TaskEventApplier {
  TaskEventApplier({required this.db, required this.local, required this.resolver});

  final AppDatabase db;
  final TaskLocalSource local;
  final ConflictResolver resolver;
  final _autoDone = StreamController<AutoDoneEvent>.broadcast();
  final _routeChanged = StreamController<void>.broadcast();

  Stream<AutoDoneEvent> get autoDone => _autoDone.stream;

  /// Something about the route changed server-side: refetch `tasks/mine`.
  Stream<void> get routeChanged => _routeChanged.stream;

  Future<void> apply(WsMessage m) async {
    final data = m.data;
    final taskId = data['task_id'] as String?;
    if (m.type == 'task.updated') {
      _routeChanged.add(null);
      return;
    }
    if (taskId == null) return;
    final row = await db.taskDao.getTask(taskId);
    if (row == null || row.role != TaskLocalSource.role) {
      // A task we do not have yet (new stop): refetch.
      if (m.type == 'task.dispatched') _routeChanged.add(null);
      return;
    }
    final before = TaskStatus.fromWire(row.status);
    final status = (data['status'] as String?) ?? m.type.substring('task.'.length);
    final source = data['source'] as String?;
    await local.applyServer(
      taskId,
      status: status,
      source: source,
      litres: (data['litres'] as num?)?.toDouble(),
      impactJson: data['impact_summary'] is Map
          ? (data['impact_summary']! as Map).cast<String, Object?>()
          : null,
      version: (data['version'] as num?)?.toInt(),
      at: m.ts,
    );
    await resolver.onServerTaskStatus(taskId, status, source: source);
    if (status == 'done' && source == 'hawatag' && !before.isCompleted) {
      _autoDone.add(
        AutoDoneEvent(
          taskId: taskId,
          sequence: row.sequence,
          litres: (data['litres'] as num?)?.toDouble(),
        ),
      );
    }
    if (status == 'cancelled') _routeChanged.add(null);
  }

  void dispose() {
    unawaited(_autoDone.close());
    unawaited(_routeChanged.close());
  }
}

/// Registered eagerly by the app wiring (`appWiringProvider`).
@Riverpod(keepAlive: true)
TaskEventApplier taskEventApplier(Ref ref) {
  final applier = TaskEventApplier(
    db: ref.watch(appDatabaseProvider),
    local: ref.watch(taskLocalSourceProvider),
    resolver: ref.watch(conflictResolverProvider),
  );
  ref.read(realtimeDispatcherProvider).on('task.', applier.apply);
  ref.onDispose(applier.dispose);
  return applier;
}
