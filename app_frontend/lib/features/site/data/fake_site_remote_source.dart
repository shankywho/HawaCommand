import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/site/data/site_remote_source.dart';

/// Dev fake: `assets/fixtures/api/sites_me.json` through the in-app [FakeBackend], parsed with the
/// generated model so the fixture is validated against the contract.
class FakeSiteRemoteSource implements SiteRemoteSource {
  FakeSiteRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<api.SiteMeOut> me() async {
    final token = await _tokens.readAccess();
    final json = await fakeCall(() => _backend.sitesMe(token: token));
    return api.SiteMeOut.fromJson(json);
  }
}
