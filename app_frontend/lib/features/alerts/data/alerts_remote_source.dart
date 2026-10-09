import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/command_center_api.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/features/alerts/data/command_center_alerts_source.dart';
import 'package:hawa_app/features/alerts/data/fake_alerts_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alerts_remote_source.g.dart';

/// `GET /v1/alerts` (cursor) and `GET /v1/alerts/{id}` in generated-client models. The ack
/// goes through the outbox (`alert_ack` executor), not through this source.
abstract interface class AlertsRemoteSource {
  Future<api.AlertPage> list({String? cursor, int? limit});

  Future<api.AlertItem> get(String id);
}

class HttpAlertsRemoteSource implements AlertsRemoteSource {
  HttpAlertsRemoteSource(this._api);

  final api.HawaApi _api;

  @override
  Future<api.AlertPage> list({String? cursor, int? limit}) async {
    try {
      return (await _api.getAlertsApi().alertsList(cursor: cursor, limit: limit)).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<api.AlertItem> get(String id) async {
    try {
      return (await _api.getAlertsApi().alertsGet(id: id)).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

/// Fake (fixtures) unless `alerts` is real. The backend's `/v1/alerts` is the command-center
/// broadcast log, not the contract inbox, so "real" uses its adapter until the contract ships
/// (`ALERTS_CONTRACT=true`).
@Riverpod(keepAlive: true)
AlertsRemoteSource alertsRemoteSource(Ref ref) {
  if (Env.isFake('alerts')) {
    return FakeAlertsRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider));
  }
  if (const bool.fromEnvironment('ALERTS_CONTRACT')) {
    return HttpAlertsRemoteSource(ref.watch(hawaApiProvider));
  }
  return CommandCenterAlertsSource(
    ref.watch(commandCenterApiProvider),
    lang: () => ref.read(appPreferencesControllerProvider).lang,
  );
}
