import 'dart:convert';

import 'package:hawa_app/core/storage/app_database.dart';

/// Operation kinds (OFFLINE_AND_SYNC §5.1) with their default priority (1 highest).
enum OpKind {
  taskAck('task_ack', 1),
  taskStatus('task_status', 1),
  inspectionClose('inspection_close', 2),
  photoUpload('photo_upload', 3),
  reportSubmit('report_submit', 2),
  alertAck('alert_ack', 1),
  shiftStart('shift_start', 1),
  shiftEnd('shift_end', 1),
  locationBatch('location_batch', 4),
  pushToken('push_token', 1),
  profileUpdate('profile_update', 4),
  unknown('unknown', 9);

  const OpKind(this.wire, this.priority);

  final String wire;
  final int priority;

  static OpKind fromWire(String w) => values.firstWhere((k) => k.wire == w, orElse: () => unknown);
}

enum OpState {
  pending('pending'),
  inFlight('in_flight'),
  done('done'),
  failed('failed'),
  superseded('superseded');

  const OpState(this.wire);

  final String wire;

  static OpState fromWire(String w) => values.firstWhere((s) => s.wire == w, orElse: () => pending);
}

/// One queued mutation. [id] is the UUIDv7 `Idempotency-Key`; [payload] never changes after
/// enqueue (editing supersedes the op and enqueues a new one).
class OutboxOp {
  const OutboxOp({
    required this.id,
    required this.userId,
    required this.kind,
    required this.orderingKey,
    required this.priority,
    required this.payload,
    required this.state,
    required this.attempts,
    required this.nextAttemptAt,
    required this.createdAt,
    required this.clientTs,
    this.dependsOn,
    this.coalesceKey,
    this.expiresAt,
    this.lastErrorCode,
    this.lastHttpStatus,
    this.result,
  });

  factory OutboxOp.fromRow(OutboxOpRow r) => OutboxOp(
    id: r.id,
    userId: r.userId,
    kind: OpKind.fromWire(r.kind),
    orderingKey: r.orderingKey,
    priority: r.priority,
    payload: (jsonDecode(r.payloadJson) as Map).cast<String, Object?>(),
    state: OpState.fromWire(r.state),
    attempts: r.attempts,
    nextAttemptAt: r.nextAttemptAt,
    createdAt: r.createdAt,
    clientTs: r.clientTs,
    dependsOn: r.dependsOn,
    coalesceKey: r.coalesceKey,
    expiresAt: r.expiresAt,
    lastErrorCode: r.lastErrorCode,
    lastHttpStatus: r.lastHttpStatus,
    result: r.resultJson == null
        ? null
        : (jsonDecode(r.resultJson!) as Map).cast<String, Object?>(),
  );

  final String id;
  final String userId;
  final OpKind kind;
  final String orderingKey;
  final int priority;
  final Map<String, Object?> payload;
  final OpState state;
  final int attempts;
  final DateTime nextAttemptAt;
  final DateTime createdAt;
  final DateTime clientTs;
  final String? dependsOn;
  final String? coalesceKey;
  final DateTime? expiresAt;
  final String? lastErrorCode;
  final int? lastHttpStatus;
  final Map<String, Object?>? result;

  String? get taskId => payload['task_id'] as String?;
}

/// Ordering keys (OFFLINE_AND_SYNC §5.1).
abstract final class OrderingKeys {
  static String task(String id) => 'task:$id';

  static String inspection(String id) => 'inspection:$id';

  static String media(String id) => 'media:$id';

  static String report(String clientReportId) => 'report:$clientReportId';

  static String alert(String id) => 'alert:$id';

  static String shift(String id) => 'shift:$id';

  static String locations(String shiftId) => 'loc:$shiftId';

  static const push = 'profile:push';

  static String profile(String field) => 'profile:$field';
}
