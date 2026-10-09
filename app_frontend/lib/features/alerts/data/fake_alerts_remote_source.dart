import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/alerts/data/alerts_remote_source.dart';

/// Alerts from the fixture backend, parsed with the generated models (validates fixtures).
class FakeAlertsRemoteSource implements AlertsRemoteSource {
  FakeAlertsRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<api.AlertPage> list({String? cursor, int? limit}) async => api.AlertPage.fromJson(
    await fakeCall(() async => _backend.alertsList(token: await _tokens.readAccess())),
  );

  @override
  Future<api.AlertItem> get(String id) async => api.AlertItem.fromJson(
    await fakeCall(() async => _backend.alertGet(id, token: await _tokens.readAccess())),
  );
}
