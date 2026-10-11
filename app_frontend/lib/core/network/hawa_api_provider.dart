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

/// Mutations for the outbox, routed per feature like the reads: an op uses the fake backend when
/// `Env.isFake(feature)`, so `USE_FAKE_API=true` plus `REAL_FEATURES=citizen_reports` sends reports
/// to the real backend while sign-in and tasks stay fake.
@Riverpod(keepAlive: true)
MutationApi mutationApi(Ref ref) {
  final http = HttpMutationApi(ref.watch(hawaApiProvider));
  if (!Env.anyFake) return http;
  final fake = FakeMutationApi(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider));
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

  /// Own feature key: the backend stores push tokens (`PUT /v1/me/push-token`) while sign-in is
  /// still fake, so list `push` in REAL_FEATURES to send them there.
  @override
  Future<Map<String, Object?>> putPushToken(Map<String, Object?> body) =>
      _for(const {'push'}).putPushToken(body);

  @override
  Future<Map<String, Object?>> patchMe(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _for(const {'auth', 'settings'}).patchMe(body, idempotencyKey: idempotencyKey);

  @override
  Future<Map<String, Object?>> putAlertSubscription(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _for(const {'citizen_subscription'}).putAlertSubscription(
    body,
    idempotencyKey: idempotencyKey,
  );

  /// Report photos follow `citizen_reports`, inspection and task photos follow `inspector`.
  @override
  Future<PresignResult> presign(Map<String, Object?> body) =>
      _for({body['purpose'] == 'report_photo' ? 'citizen_reports' : 'inspector'}).presign(body);
}
