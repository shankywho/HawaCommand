import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/citizen_air/data/fake_subscription_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subscription_remote_source.g.dart';

/// Proposed `GET /v1/me/alert-subscription`. Writes go through the outbox (`profile_update`).
// One interface so the fake and HTTP sources swap behind one provider (ARCHITECTURE §2).
// ignore: one_member_abstracts
abstract interface class SubscriptionRemoteSource {
  Future<api.AlertSubscription> get();
}

class HttpSubscriptionRemoteSource implements SubscriptionRemoteSource {
  HttpSubscriptionRemoteSource(this._api);

  final api.HawaApi _api;

  @override
  Future<api.AlertSubscription> get() async {
    try {
      return (await _api.getMeApi().meGetAlertSubscription()).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

/// The backend has no subscription endpoint yet, so this follows its own feature key
/// (`citizen_subscription`), fake unless listed in `REAL_FEATURES`.
@Riverpod(keepAlive: true)
SubscriptionRemoteSource subscriptionRemoteSource(Ref ref) => Env.isFake('citizen_subscription')
    ? FakeSubscriptionRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
    : HttpSubscriptionRemoteSource(ref.watch(hawaApiProvider));
