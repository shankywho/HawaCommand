import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/realtime/realtime_dispatcher.dart';
import 'package:hawa_app/core/realtime/ws_message.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/sync/outbox_repository.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/alerts/data/alert_mapper.dart';
import 'package:hawa_app/features/alerts/data/alerts_local_source.dart';
import 'package:hawa_app/features/alerts/data/alerts_remote_source.dart';
import 'package:hawa_app/features/alerts/data/command_center_alerts_source.dart';
import 'package:hawa_app/features/alerts/domain/alerts_repository.dart';
import 'package:hawa_app/features/alerts/domain/app_alert.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alerts_repository_impl.g.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  AlertsRepositoryImpl({
    required this.remote,
    required this.local,
    required this.db,
    required this.outbox,
    required this.clock,
  });

  final AlertsRemoteSource remote;
  final AlertsLocalSource local;
  final AppDatabase db;
  final OutboxRepository outbox;
  final Clock clock;

  /// Inbox cap (OFFLINE_AND_SYNC §2: 30 days or 200 newest).
  static const maxAlerts = 200;
  static const keepFor = Duration(days: 30);

  @override
  Stream<List<AppAlert>> watchInbox() => local.watchInbox();

  @override
  Stream<AppAlert?> watchAlert(String id) => local.watchAlert(id);

  @override
  Stream<DateTime?> watchLastSuccess() => local.watchLastSuccess();

  @override
  Future<void> refresh() async {
    final now = clock.now().toUtc();
    try {
      final items = <api.AlertItem>[];
      String? cursor;
      do {
        final page = await remote.list(cursor: cursor, limit: 100);
        items.addAll(page.items);
        cursor = page.nextCursor;
      } while (cursor != null && items.length < maxAlerts);
      await local.upsert([for (final a in items) AlertMapper.toRow(a)]);
      await local.prune(now.subtract(keepFor));
      await local.markSuccess(now);
    } on Object catch (e) {
      await local.markAttempt(now, _codeOf(e));
      rethrow;
    }
  }

  @override
  Future<AppAlert> fetch(String id) async {
    final item = await remote.get(id);
    await local.upsert([AlertMapper.toRow(item)]);
    return (await local.get(id))!;
  }

  @override
  Future<void> markRead(String id) => local.markRead(id, clock.now().toUtc());

  @override
  Future<bool> acknowledge(String id) {
    final now = clock.now().toUtc();
    return db.transaction(() async {
      final current = await local.get(id);
      if (current == null || current.isAcked) return false;
      await local.markAcked(id, now);
      // Command-center broadcasts have no ack endpoint yet: the ack stays on the phone.
      if (id.startsWith(CommandCenterAlertsSource.idPrefix)) return true;
      final opId = await outbox.enqueue(
        kind: OpKind.alertAck,
        orderingKey: OrderingKeys.alert(id),
        payload: {'alert_id': id, 'at': now.toIso8601String()},
        clientTs: now,
        dedupe: true,
      );
      return opId != null;
    });
  }

  @override
  Future<bool> applyRealtime(
    Map<String, Object?> data, {
    required String? activeRole,
    DateTime? eventTs,
  }) async {
    if (activeRole == null || data['audience'] != activeRole) return false;
    final row = AlertMapper.fromRealtime(data, now: clock.now().toUtc(), eventTs: eventTs);
    if (row == null) return false;
    // The REST copy is authoritative: a WS echo of a cached alert changes nothing.
    if (await local.get(row.id.value) != null) return true;
    await local.upsert([row]);
    return true;
  }

  static String _codeOf(Object e) =>
      e is Failure ? (e.code ?? e.runtimeType.toString()) : e.runtimeType.toString();
}

@Riverpod(keepAlive: true)
AlertsRepository alertsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return AlertsRepositoryImpl(
    remote: ref.watch(alertsRemoteSourceProvider),
    local: AlertsLocalSource(db),
    db: db,
    outbox: ref.watch(outboxRepositoryProvider),
    clock: ref.watch(appClockProvider),
  );
}

/// Applies `alert.*` WebSocket events to the inbox (ARCHITECTURE §10.1), for the active role.
class AlertEventApplier {
  AlertEventApplier({required this.repository, required this.activeRole});

  final AlertsRepository Function() repository;
  final String? Function() activeRole;

  Future<void> handle(WsMessage message) async {
    await repository().applyRealtime(message.data, activeRole: activeRole(), eventTs: message.ts);
  }
}

/// Registers the `alert.` realtime handler; the app reads it eagerly at start.
@Riverpod(keepAlive: true)
AlertEventApplier alertEventApplier(Ref ref) {
  final applier = AlertEventApplier(
    repository: () => ref.read(alertsRepositoryProvider),
    activeRole: () => ref.read(activeRoleWireProvider),
  );
  ref.watch(realtimeDispatcherProvider).on('alert.', applier.handle);
  return applier;
}
