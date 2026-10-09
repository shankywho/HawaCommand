import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';

/// [MutationApi] against the in-app [FakeBackend] (dev fake mode).
class FakeMutationApi implements MutationApi {
  FakeMutationApi(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  Future<String?> get _token => _tokens.readAccess();

  String _iso(DateTime t) => t.toUtc().toIso8601String();

  @override
  Future<Map<String, Object?>> ackTask(
    String taskId, {
    required DateTime at,
    required String idempotencyKey,
  }) async => fakeCall(
    () async =>
        _backend.taskAck(taskId, {'at': _iso(at)}, token: await _token, key: idempotencyKey),
  );

  @override
  Future<Map<String, Object?>> updateTaskStatus(
    String taskId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => fakeCall(
    () async => _backend.taskStatus(taskId, body, token: await _token, key: idempotencyKey),
  );

  @override
  Future<Map<String, Object?>> closeInspection(
    String inspectionId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => fakeCall(
    () async =>
        _backend.inspectionClose(inspectionId, body, token: await _token, key: idempotencyKey),
  );

  @override
  Future<Map<String, Object?>> markOnSite(
    String inspectionId, {
    required DateTime at,
    required String idempotencyKey,
  }) => fakeCall(
    () async => _backend.inspectionOnSite(
      inspectionId,
      {'at': _iso(at)},
      token: await _token,
      key: idempotencyKey,
    ),
  );

  @override
  Future<Map<String, Object?>> createReport(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) =>
      fakeCall(() async => _backend.reportsCreate(body, token: await _token, key: idempotencyKey));

  @override
  Future<Map<String, Object?>> ackAlert(
    String alertId, {
    required DateTime at,
    required String idempotencyKey,
  }) => fakeCall(
    () async =>
        _backend.alertAck(alertId, {'at': _iso(at)}, token: await _token, key: idempotencyKey),
  );

  @override
  Future<Map<String, Object?>> shiftAction(
    String shiftId,
    String action,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => fakeCall(
    () async =>
        _backend.shiftAction(shiftId, action, body, token: await _token, key: idempotencyKey),
  );

  @override
  Future<Map<String, Object?>> postLocations(
    String shiftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => fakeCall(
    () async => _backend.shiftLocations(shiftId, body, token: await _token, key: idempotencyKey),
  );

  @override
  Future<Map<String, Object?>> putPushToken(Map<String, Object?> body) =>
      fakeCall(() async => _backend.putPushToken(body, token: await _token));

  @override
  Future<Map<String, Object?>> patchMe(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => fakeCall(() async => _backend.patchMe(body, token: await _token, key: idempotencyKey));

  @override
  Future<Map<String, Object?>> putAlertSubscription(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => fakeCall(
    () async => _backend.putAlertSubscription(body, token: await _token, key: idempotencyKey),
  );

  @override
  Future<PresignResult> presign(Map<String, Object?> body) async => PresignResult.fromJson(
    await fakeCall(() async => _backend.presign(body, token: await _token)),
  );
}
