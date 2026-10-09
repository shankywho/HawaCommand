import 'package:hawa_api/hawa_api.dart';
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/dio_provider.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/fake/fake_mutation_api.dart';
import 'package:hawa_app/core/network/http_mutation_api.dart';
import 'package:hawa_app/core/network/mutation_api.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hawa_api_provider.g.dart';

/// The generated client on our Dio (shared interceptor chain). The only place it is built;
/// `interceptors: []` stops it adding its own auth interceptors.
@Riverpod(keepAlive: true)
HawaApi hawaApi(Ref ref) => HawaApi(dio: ref.watch(dioProvider), interceptors: const []);

/// Mutations for the outbox: the fake backend in fake mode, otherwise the generated client.
/// With `FAKE_FEATURES`, an op uses the fake backend when its feature is listed.
@Riverpod(keepAlive: true)
MutationApi mutationApi(Ref ref) {
  final http = Env.useFakeApi ? null : HttpMutationApi(ref.watch(hawaApiProvider));
  final fake = Env.anyFake
      ? FakeMutationApi(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
      : null;
  if (http == null) return fake!;
  if (fake == null) return http;
  return _RoutingMutationApi(http: http, fake: fake);
}

class _RoutingMutationApi implements MutationApi {
  _RoutingMutationApi({required this.http, required this.fake});

  final MutationApi http;
  final MutationApi fake;

  MutationApi _for(Set<String> features) => features.any(Env.isFake) ? fake : http;

  MutationApi get _tasks => _for(const {'driver_route', 'inspector'});

  @override
  Future<Map<String, Object?>> ackTask(
    String taskId, {
    required DateTime at,
    required String idempotencyKey,
  }) => _tasks.ackTask(taskId, at: at, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> updateTaskStatus(
    String taskId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _tasks.updateTaskStatus(taskId, body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> closeInspection(
    String inspectionId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) =>
      _for(const {'inspector'}).closeInspection(inspectionId, body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> markOnSite(
    String inspectionId, {
    required DateTime at,
    required String idempotencyKey,
  }) => _for(const {'inspector'}).markOnSite(inspectionId, at: at, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> createReport(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _for(const {'citizen_reports'}).createReport(body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> ackAlert(
    String alertId, {
    required DateTime at,
    required String idempotencyKey,
  }) => _for(const {'alerts', 'school'}).ackAlert(alertId, at: at, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> shiftAction(
    String shiftId,
    String action,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _tasks.shiftAction(shiftId, action, body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> postLocations(
    String shiftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _tasks.postLocations(shiftId, body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> putPushToken(Map<String, Object?> body) =>
      _for(const {'auth'}).putPushToken(body);

  @override
  Future<Map<String, Object?>> patchMe(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _for(const {'auth', 'settings'}).patchMe(body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> putAlertSubscription(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _for(const {'citizen_air'}).putAlertSubscription(body, idempotencyKey: idempotencyKey);

  @override
  Future<PresignResult> presign(Map<String, Object?> body) =>
      _for(const {'citizen_reports', 'inspector'}).presign(body);
}
