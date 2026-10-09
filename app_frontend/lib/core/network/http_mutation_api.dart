import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart';
import 'package:hawa_app/core/network/interceptors/idempotency_interceptor.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/network/mutation_api.dart';

/// [MutationApi] over the generated client. The only place outbox calls touch `hawa_api`.
class HttpMutationApi implements MutationApi {
  HttpMutationApi(this._api);

  final HawaApi _api;

  Map<String, Object?> _extra(String key) => {IdempotencyInterceptor.extraKey: key};

  Future<Map<String, Object?>> _run<T>(
    Future<Response<T>> Function() call,
    Map<String, Object?> Function(T) toJson,
  ) async {
    try {
      final res = await call();
      final data = res.data;
      return data == null ? <String, Object?>{} : toJson(data);
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<Map<String, Object?>> ackTask(
    String taskId, {
    required DateTime at,
    required String idempotencyKey,
  }) => _run(
    () => _api.getTasksApi().tasksAck(
      id: taskId,
      taskAckIn: TaskAckIn(at: at.toUtc()),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> updateTaskStatus(
    String taskId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _run(
    () => _api.getTasksApi().tasksUpdateStatus(
      id: taskId,
      taskStatusIn: TaskStatusIn.fromJson(body),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> closeInspection(
    String inspectionId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _run(
    () => _api.getInspectionsApi().inspectionsClose(
      id: inspectionId,
      inspectionCloseIn: InspectionCloseIn.fromJson(body),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> markOnSite(
    String inspectionId, {
    required DateTime at,
    required String idempotencyKey,
  }) => _run(
    () => _api.getInspectionsApi().inspectionsOnSite(
      id: inspectionId,
      onSiteIn: OnSiteIn(at: at.toUtc()),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> createReport(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _run(
    () => _api.getReportsApi().reportsCreate(
      reportCreateIn: ReportCreateIn.fromJson(body),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> ackAlert(
    String alertId, {
    required DateTime at,
    required String idempotencyKey,
  }) => _run(
    () => _api.getAlertsApi().alertsAck(
      id: alertId,
      alertAckIn: AlertAckIn(at: at.toUtc()),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> shiftAction(
    String shiftId,
    String action,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) {
    final shifts = _api.getShiftsApi();
    final input = ShiftActionIn.fromJson(body);
    return _run(
      () => action == 'start'
          ? shifts.shiftsStart(
              id: shiftId,
              shiftActionIn: input,
              idempotencyKey: idempotencyKey,
              extra: _extra(idempotencyKey),
            )
          : shifts.shiftsEnd(
              id: shiftId,
              shiftActionIn: input,
              idempotencyKey: idempotencyKey,
              extra: _extra(idempotencyKey),
            ),
      (d) => d.toJson(),
    );
  }

  @override
  Future<Map<String, Object?>> postLocations(
    String shiftId,
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _run(
    () => _api.getShiftsApi().shiftsLocations(
      id: shiftId,
      locationBatchIn: LocationBatchIn.fromJson(body),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> putPushToken(Map<String, Object?> body) => _run(
    () => _api.getMeApi().mePutPushToken(pushTokenIn: PushTokenIn.fromJson(body)),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> patchMe(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _run(
    () => _api.getMeApi().mePatch(
      mePatchIn: MePatchIn.fromJson(body),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<Map<String, Object?>> putAlertSubscription(
    Map<String, Object?> body, {
    required String idempotencyKey,
  }) => _run(
    () => _api.getMeApi().mePutAlertSubscription(
      alertSubscription: AlertSubscription.fromJson(body),
      idempotencyKey: idempotencyKey,
      extra: _extra(idempotencyKey),
    ),
    (d) => d.toJson(),
  );

  @override
  Future<PresignResult> presign(Map<String, Object?> body) async {
    final json = await _run(
      () => _api.getUploadsApi().uploadsPresign(presignIn: PresignIn.fromJson(body)),
      (d) => d.toJson(),
    );
    return PresignResult.fromJson(json);
  }
}
