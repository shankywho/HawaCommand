/// A presigned upload target (backend ARCHITECTURE §7 "Uploads").
class PresignResult {
  const PresignResult({
    required this.key,
    required this.url,
    required this.method,
    required this.expiresAt,
    this.fields = const {},
    this.headers = const {},
    this.maxBytes,
  });

  factory PresignResult.fromJson(Map<String, Object?> json) => PresignResult(
    key: json['key']! as String,
    url: json['url']! as String,
    method: (json['method'] as String? ?? 'POST').toUpperCase(),
    expiresAt: DateTime.parse(json['expires_at']! as String),
    fields: {
      for (final e in (json['fields'] as Map? ?? const {}).entries)
        e.key.toString(): e.value.toString(),
    },
    headers: {
      for (final e in (json['headers'] as Map? ?? const {}).entries)
        e.key.toString(): e.value.toString(),
    },
    maxBytes: (json['max_bytes'] as num?)?.toInt(),
  );

  final String key;
  final String url;

  /// `POST`: multipart form (fields first, then `file`). `PUT`: raw body with [headers].
  final String method;
  final DateTime expiresAt;
  final Map<String, String> fields;
  final Map<String, String> headers;
  final int? maxBytes;
}

/// Every state-changing `/v1` call the outbox executors make (OFFLINE_AND_SYNC §5.1).
///
/// Bodies are plain JSON maps so `core/sync` never imports the generated client; the HTTP
/// implementation in core/network maps them onto `package:hawa_api`. Each call takes the outbox
/// op id as its `Idempotency-Key`.
abstract interface class MutationApi {
  Future<Map<String, Object?>> ackTask(
    String taskId, {
    required DateTime at,
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> updateTaskStatus(
    String taskId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> closeInspection(
    String inspectionId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> markOnSite(
    String inspectionId, {
    required DateTime at,
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> createReport(
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> ackAlert(
    String alertId, {
    required DateTime at,
    required String idempotencyKey,
  });

  /// [action] is `start` or `end`.
  Future<Map<String, Object?>> shiftAction(
    String shiftId,
    String action,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> postLocations(
    String shiftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<Map<String, Object?>> putPushToken(Map<String, Object?> body);

  Future<Map<String, Object?>> patchMe(Map<String, Object?> body, {required String idempotencyKey});

  Future<Map<String, Object?>> putAlertSubscription(
    Map<String, Object?> body, {
    required String idempotencyKey,
  });

  Future<PresignResult> presign(Map<String, Object?> body);
}
