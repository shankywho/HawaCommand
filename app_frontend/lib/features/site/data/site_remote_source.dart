import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/site/data/fake_site_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'site_remote_source.g.dart';

/// `GET /v1/sites/me` in generated-client models.
// One method on purpose: the Http and Fake implementations are swapped per feature (PLAN §6).
// ignore: one_member_abstracts
abstract interface class SiteRemoteSource {
  Future<api.SiteMeOut> me();
}

class HttpSiteRemoteSource implements SiteRemoteSource {
  HttpSiteRemoteSource(this._api);

  final api.HawaApi _api;

  @override
  Future<api.SiteMeOut> me() async {
    try {
      return (await _api.getSitesApi().sitesMe()).data!;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }
}

@Riverpod(keepAlive: true)
SiteRemoteSource siteRemoteSource(Ref ref) => Env.isFake('site')
    ? FakeSiteRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
    : HttpSiteRemoteSource(ref.watch(hawaApiProvider));
