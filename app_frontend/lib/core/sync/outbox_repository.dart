import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'outbox_repository.g.dart';

/// The signed-in user id. Ops are owned by a user and never cross users
/// (OFFLINE_AND_SYNC §10). Set by the session controller.
@Riverpod(keepAlive: true)
class CurrentUserId extends _$CurrentUserId {
  @override
  String? build() => null;

  // A notifier command (`ref.read(p.notifier).set(…)`) reads better than a setter here.
  // ignore: use_setters_to_change_properties
  void set(String? userId) => state = userId;
}

/// Enqueue mutations (call it inside the same drift transaction as the optimistic change) and
/// watch the queue.
class OutboxRepository {
  OutboxRepository({
    required this.db,
    required this.clock,
    required this.userId,
    required this.onEnqueued,
  });

  final AppDatabase db;
  final Clock clock;
  final String? Function() userId;

  /// Kicks the drainer after the enclosing transaction commits.
  final void Function() onEnqueued;

  /// Expiry defaults per kind (OFFLINE_AND_SYNC §5.1).
  static Duration? defaultExpiry(OpKind kind, Map<String, Object?> payload) => switch (kind) {
    OpKind.taskStatus =>
      const {'en_route', 'in_progress'}.contains(payload['status'])
          ? const Duration(hours: 12)
          : null,
    OpKind.alertAck => const Duration(days: 7),
    OpKind.shiftStart || OpKind.shiftEnd => const Duration(hours: 24),
    OpKind.locationBatch => const Duration(hours: 6),
    _ => null,
  };

  /// Returns the op id, or null when [dedupe] found a live op of the same kind and key
  /// (`task_ack`, `alert_ack`: one per entity).
  Future<String?> enqueue({
    required OpKind kind,
    required String orderingKey,
    required Map<String, Object?> payload,
    String? dependsOn,
    String? coalesceKey,
    DateTime? expiresAt,
    DateTime? clientTs,
    String? id,
    bool dedupe = false,
  }) async {
    final owner = userId();
    if (owner == null) throw StateError('outbox: no signed-in user');
    final opId = id ?? newId();
    final now = clock.now().toUtc();
    final inserted = await db.transaction(() async {
      if (dedupe && await db.outboxDao.hasLiveOp(kind.wire, orderingKey)) return false;
      if (coalesceKey != null) await db.outboxDao.supersedeCoalesced(coalesceKey, now);
      final ttl = defaultExpiry(kind, payload);
      await db.outboxDao.insertOp(
        OutboxOpsTableCompanion.insert(
          id: opId,
          userId: owner,
          kind: kind.wire,
          orderingKey: orderingKey,
          dependsOn: Value(dependsOn),
          coalesceKey: Value(coalesceKey),
          priority: kind.priority,
          payloadJson: jsonEncode(payload),
          state: OpState.pending.wire,
          nextAttemptAt: now,
          expiresAt: Value(expiresAt ?? (ttl == null ? null : now.add(ttl))),
          createdAt: now,
          clientTs: clientTs ?? now,
        ),
      );
      return true;
    });
    if (!inserted) return null;
    // After the caller's transaction has committed.
    Timer.run(onEnqueued);
    return opId;
  }

  Stream<int> watchDepth() {
    final owner = userId();
    return owner == null ? Stream.value(0) : db.outboxDao.watchDepth(owner);
  }

  Stream<List<OutboxOp>> watchVisible() {
    final owner = userId();
    if (owner == null) return Stream.value(const []);
    return db.outboxDao.watchVisible(owner).map((rows) => rows.map(OutboxOp.fromRow).toList());
  }

  Future<int> depth() async {
    final owner = userId();
    return owner == null ? 0 : db.outboxDao.depth(owner);
  }

  /// Unsent ops on one key (for overlays and conflict resolution).
  Future<List<OutboxOp>> activeFor(String orderingKey) async =>
      (await db.outboxDao.activeFor(orderingKey)).map(OutboxOp.fromRow).toList();

  Future<void> retryNow(String id) async {
    await db.outboxDao.retryNow(id, clock.now().toUtc());
    onEnqueued();
  }

  /// Discard a permanently failed op (confirmed in `/settings/sync`).
  Future<void> discard(String id) =>
      db.outboxDao.markSuperseded(id, code: 'discarded', now: clock.now().toUtc());
}

@Riverpod(keepAlive: true)
OutboxRepository outboxRepository(Ref ref) => OutboxRepository(
  db: ref.watch(appDatabaseProvider),
  clock: ref.watch(appClockProvider),
  userId: () => ref.read(currentUserIdProvider),
  onEnqueued: () => ref.read(outboxKickProvider)(),
);

/// Indirection so the repository does not depend on the drainer (bound by the drainer provider).
/// A plain holder, not provider state: binding happens while the drainer provider builds, and
/// Riverpod forbids notifying listeners from inside another provider's build.
class OutboxKick {
  void Function() _kick = _noop;

  static void _noop() {}

  // A callable holder: the repository calls `kick()` without knowing the drainer.
  // ignore: use_setters_to_change_properties
  void bind(void Function() kick) => _kick = kick;

  void call() => _kick();
}

@Riverpod(keepAlive: true)
OutboxKick outboxKick(Ref ref) => OutboxKick();

/// Unsent op count for the sync chip.
@riverpod
Stream<int> outboxDepth(Ref ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(outboxRepositoryProvider).watchDepth();
}

/// Ops shown in `/settings/sync` (pending, in flight, failed).
@riverpod
Stream<List<OutboxOp>> visibleOutboxOps(Ref ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(outboxRepositoryProvider).watchVisible();
}
