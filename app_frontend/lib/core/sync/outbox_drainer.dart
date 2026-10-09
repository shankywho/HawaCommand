import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:hawa_app/core/errors/crash_reporter.dart';
import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/storage/app_database.dart';
import 'package:hawa_app/core/storage/daos/outbox_dao.dart';
import 'package:hawa_app/core/sync/backoff.dart';
import 'package:hawa_app/core/sync/conflict_banner_bus.dart';
import 'package:hawa_app/core/sync/executors/op_executor.dart';
import 'package:hawa_app/core/sync/outbox_op.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/core/utils/ids.dart';
import 'package:logging/logging.dart';

/// How a failed attempt is handled (OFFLINE_AND_SYNC §5.5).
sealed class OpOutcome {
  const OpOutcome();
}

final class OutcomeDone extends OpOutcome {
  const OutcomeDone(this.result);

  final Map<String, Object?>? result;
}

final class OutcomeRetry extends OpOutcome {
  const OutcomeRetry({this.retryAfter, this.code, this.status});

  final Duration? retryAfter;
  final String? code;
  final int? status;
}

/// Back to pending without consuming an attempt (offline); the pass stops.
final class OutcomeRelease extends OpOutcome {
  const OutcomeRelease();
}

final class OutcomeSuperseded extends OpOutcome {
  const OutcomeSuperseded(this.code, this.notice);

  final String? code;
  final ConflictKind? notice;
}

final class OutcomeFailed extends OpOutcome {
  const OutcomeFailed(this.code, this.status);

  final String? code;
  final int? status;
}

/// 401: the refresh path owns it; the drainer pauses until the same user is signed in again.
final class OutcomePause extends OpOutcome {
  const OutcomePause();
}

/// Single drainer per process: lease row, head-of-line per ordering key, dependencies, priority,
/// at most 3 in flight and 1 photo upload on mobile data (OFFLINE_AND_SYNC §5.2, §5.6).
class OutboxDrainer {
  OutboxDrainer({
    required this.db,
    required List<OpExecutor> executors,
    required this.clock,
    required this.userId,
    required this.isOffline,
    required this.isMobileData,
    required this.publish,
    this.crash,
    this.onForbidden,
    Random? random,
  }) : _executors = {for (final e in executors) e.kind: e},
       _random = random ?? Random();

  final AppDatabase db;
  final Map<OpKind, OpExecutor> _executors;
  final Clock clock;
  final String? Function() userId;
  final bool Function() isOffline;
  final bool Function() isMobileData;
  final void Function(ConflictNotice) publish;
  final CrashReporter? crash;
  final void Function()? onForbidden;
  final Random _random;

  static const maxInFlight = 3;
  static const leaseTtl = Duration(minutes: 2);
  static final _log = Logger('outbox');

  final String _owner = newId();
  bool _running = false;
  bool _again = false;
  bool _paused = false;
  bool _started = false;
  Timer? _wake;
  final _activity = StreamController<bool>.broadcast();

  /// `true` while a drain pass runs (the sync chip shows progress).
  Stream<bool> get activity => _activity.stream;

  bool get isPaused => _paused;

  /// In-flight rows found at startup were interrupted; replaying with the same key is safe.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await db.outboxDao.resetInFlight();
    kick();
  }

  void pause() => _paused = true;

  void resume() {
    _paused = false;
    kick();
  }

  void kick() {
    if (_running) {
      _again = true;
      return;
    }
    unawaited(_drain());
  }

  /// Logout "Send now": drain with a time budget; returns the remaining depth.
  Future<int> drainNow({Duration budget = const Duration(seconds: 20)}) async {
    final deadline = clock.now().add(budget);
    while (clock.now().isBefore(deadline)) {
      await _drain(force: true);
      final owner = userId();
      if (owner == null) return 0;
      final depth = await db.outboxDao.depth(owner);
      if (depth == 0 || isOffline()) return depth;
      final next = await db.outboxDao.nextWakeUp(owner);
      final wait = next == null ? Duration.zero : next.difference(clock.now().toUtc());
      if (wait > const Duration(seconds: 3)) return depth;
      await Future<void>.delayed(wait > Duration.zero ? wait : const Duration(milliseconds: 200));
    }
    final owner = userId();
    return owner == null ? 0 : db.outboxDao.depth(owner);
  }

  void dispose() {
    _wake?.cancel();
    unawaited(_activity.close());
  }

  Future<void> _drain({bool force = false}) async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    _activity.add(true);
    try {
      do {
        _again = false;
        if (_paused || userId() == null || isOffline()) break;
        final now = clock.now().toUtc();
        if (!await db.syncStateDao.tryAcquireLease(_owner, now: now, ttl: leaseTtl)) {
          _schedule(const Duration(seconds: 30));
          break;
        }
        try {
          await _pass(force: force);
        } finally {
          await db.syncStateDao.releaseLease(_owner);
        }
      } while (_again);
    } on Object catch (e, st) {
      _log.warning('drain failed', e, st);
    } finally {
      _running = false;
      if (!_activity.isClosed) _activity.add(false);
    }
    await _scheduleNext();
  }

  Future<void> _pass({required bool force}) async {
    while (!_paused && !isOffline()) {
      final batch = await _readyBatch(force: force);
      if (batch.isEmpty) return;
      await db.syncStateDao.tryAcquireLease(_owner, now: clock.now().toUtc(), ttl: leaseTtl);
      final stop = await Future.wait(batch.map(_run));
      if (stop.any((s) => s)) return;
    }
  }

  /// Ready ops (§5.2), by priority then age, honouring the concurrency limits.
  Future<List<OutboxOp>> _readyBatch({required bool force}) async {
    final owner = userId();
    if (owner == null) return const [];
    final now = clock.now().toUtc();
    final candidates = await db.outboxDao.pendingOps(owner);
    final ready = <OutboxOp>[];
    final keysTaken = <String>{};
    var photos = 0;
    for (final row in candidates) {
      if (ready.length >= maxInFlight) break;
      final op = OutboxOp.fromRow(row);
      if (op.expiresAt != null && !op.expiresAt!.isAfter(now)) {
        await _supersede(op, 'expired', null);
        continue;
      }
      if (!force && op.nextAttemptAt.isAfter(now)) continue;
      if (keysTaken.contains(op.orderingKey)) continue;
      final head = await db.outboxDao.headOf(op.orderingKey);
      if (head != null && head.id != op.id) continue;
      if (!await _dependencyReady(op)) continue;
      if (op.kind == OpKind.photoUpload && isMobileData()) {
        if (photos >= 1) continue;
        photos++;
      }
      keysTaken.add(op.orderingKey);
      ready.add(op);
    }
    return ready;
  }

  /// done → ready; failed → this fails; superseded → this is superseded; pending → wait.
  Future<bool> _dependencyReady(OutboxOp op) async {
    final depId = op.dependsOn;
    if (depId == null) return true;
    final dep = await db.outboxDao.getOp(depId);
    if (dep == null || dep.state == OutboxDao.done) return true;
    if (dep.state == OutboxDao.failed) {
      await _fail(op, 'dependency_failed', null);
      return false;
    }
    if (dep.state == OutboxDao.superseded) {
      await _supersede(op, 'dependency_superseded', null);
      return false;
    }
    return false;
  }

  /// Runs one op; returns true when the pass should stop (offline or paused).
  Future<bool> _run(OutboxOp op) async {
    final executor = _executors[op.kind];
    if (executor == null) {
      await _fail(op, 'no_executor', null);
      return false;
    }
    await db.outboxDao.markInFlight(op.id);
    OpOutcome outcome;
    try {
      outcome = OutcomeDone(await executor.execute(op));
    } on Failure catch (f) {
      outcome = classify(op, f, executor);
    } on Object catch (e, st) {
      _log.warning('executor ${op.kind.wire} crashed', e, st);
      outcome = op.attempts >= 5
          ? const OutcomeFailed('client_error', null)
          : const OutcomeRetry(code: 'client_error');
    }
    return _apply(op, executor, outcome);
  }

  /// The §5.5 table.
  OpOutcome classify(OutboxOp op, Failure f, OpExecutor executor) {
    final code = f.code;
    switch (f) {
      case NetworkFailure() || SimulatedOfflineFailure():
        return isOffline() ? const OutcomeRelease() : const OutcomeRetry(code: 'network');
      case TimeoutFailure():
        return const OutcomeRetry(code: 'timeout', status: 408);
      case RateLimitedFailure(:final retryAfter):
        return OutcomeRetry(retryAfter: retryAfter, code: code ?? 'rate_limited', status: 429);
      case ServerFailure(:final status):
        return OutcomeRetry(code: code, status: status);
      case UnauthorizedFailure():
        return const OutcomePause();
      case ForbiddenFailure():
        onForbidden?.call();
        return OutcomeFailed(code ?? 'forbidden', 403);
      case NotFoundFailure():
        return OutcomeSuperseded(code ?? 'not_found', executor.conflictFor(op, f));
      case ConflictFailure(:final retryAfter):
        if (code == 'idempotency_in_progress') {
          return OutcomeRetry(
            retryAfter: retryAfter ?? const Duration(seconds: 1),
            code: code,
            status: 409,
          );
        }
        if (code == 'already_in_state' || code == 'transition_already_past') {
          return const OutcomeDone(null);
        }
        if (code == 'task_already_done' ||
            code == 'task_cancelled' ||
            code == 'inspection_already_closed' ||
            code == 'task.invalid_transition') {
          return OutcomeSuperseded(code, executor.conflictFor(op, f));
        }
        return OutcomeFailed(code, 409);
      case ValidationFailure(:final status):
        if (code == 'idempotency_key_mismatch') {
          unawaited(crash?.nonFatal(f, code: code));
        }
        return OutcomeFailed(code ?? 'validation_failed', status);
      case UnknownFailure():
        return op.attempts >= 5
            ? OutcomeFailed(code ?? 'unknown', null)
            : OutcomeRetry(code: code ?? 'unknown');
    }
  }

  Future<bool> _apply(OutboxOp op, OpExecutor executor, OpOutcome outcome) async {
    final now = clock.now().toUtc();
    switch (outcome) {
      case OutcomeDone(:final result):
        await db.outboxDao.markDone(
          op.id,
          now: now,
          resultJson: result == null ? null : jsonEncode(result),
        );
        await _settle(executor, op, OpState.done, result);
        return false;
      case OutcomeRetry(:final retryAfter, :final code, :final status):
        final attempts = op.attempts + 1;
        await db.outboxDao.reschedule(
          op.id,
          attempts: attempts,
          next: now.add(nextDelay(attempts, retryAfter: retryAfter, rng: _random)),
          code: code,
          httpStatus: status,
        );
        return false;
      case OutcomeRelease():
        await db.outboxDao.release(op.id);
        return true;
      case OutcomePause():
        await db.outboxDao.release(op.id);
        _paused = true;
        return true;
      case OutcomeSuperseded(:final code, :final notice):
        await _supersede(op, code, notice, executor: executor);
        return false;
      case OutcomeFailed(:final code, :final status):
        await _fail(op, code, status, executor: executor);
        return false;
    }
  }

  Future<void> _supersede(
    OutboxOp op,
    String? code,
    ConflictKind? notice, {
    OpExecutor? executor,
  }) async {
    final now = clock.now().toUtc();
    await db.outboxDao.markSuperseded(op.id, code: code, now: now);
    if (notice != null) {
      publish(
        ConflictNotice(
          kind: notice,
          entityId: op.taskId ?? op.payload['inspection_id']?.toString() ?? op.id,
          at: now,
        ),
      );
    }
    await _settle(executor ?? _executors[op.kind], op, OpState.superseded, null);
  }

  Future<void> _fail(OutboxOp op, String? code, int? status, {OpExecutor? executor}) async {
    await db.outboxDao.markFailed(op.id, code: code, httpStatus: status, now: clock.now().toUtc());
    unawaited(crash?.nonFatal(StateError('outbox ${op.kind.wire} failed'), code: code));
    await _settle(executor ?? _executors[op.kind], op, OpState.failed, null);
  }

  Future<void> _settle(
    OpExecutor? executor,
    OutboxOp op,
    OpState state,
    Map<String, Object?>? result,
  ) async {
    try {
      await executor?.onSettled(op, state, result: result);
    } on Object catch (e, st) {
      _log.warning('onSettled ${op.kind.wire}', e, st);
    }
  }

  Future<void> _scheduleNext() async {
    String? owner;
    try {
      owner = userId();
    } catch (_) {
      return;
    }
    if (owner == null || _paused) return;
    final next = await db.outboxDao.nextWakeUp(owner);
    if (next == null) return;
    final wait = next.difference(clock.now().toUtc());
    _schedule(wait.isNegative ? const Duration(milliseconds: 100) : wait);
  }

  void _schedule(Duration wait) {
    _wake?.cancel();
    _wake = Timer(wait, kick);
  }
}
