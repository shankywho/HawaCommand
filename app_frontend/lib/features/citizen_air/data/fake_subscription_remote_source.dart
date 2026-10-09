import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/citizen_air/data/subscription_remote_source.dart';

/// The subscription from `alert_subscription.json` (PUTs go through the fake mutation API).
class FakeSubscriptionRemoteSource implements SubscriptionRemoteSource {
  FakeSubscriptionRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<api.AlertSubscription> get() async => api.AlertSubscription.fromJson(
    await fakeCall(() async => _backend.getAlertSubscription(token: await _tokens.readAccess())),
  );
}
