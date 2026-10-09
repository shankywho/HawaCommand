import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/network/fake/fake_backend.dart';
import 'package:hawa_app/core/network/fake/fake_call.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/auth/data/auth_remote_source.dart';

/// (dev) OTP `123456`; demo numbers map to fixture users (FakeBackend.phoneFixtures).
class FakeAuthRemoteSource implements AuthRemoteSource {
  FakeAuthRemoteSource(this._backend, this._tokens);

  final FakeBackend _backend;
  final TokenStore _tokens;

  @override
  Future<api.OtpRequestOut> requestOtp(api.OtpRequestIn body) async =>
      api.OtpRequestOut.fromJson(await fakeCall(() => _backend.otpRequest(body.toJson())));

  @override
  Future<api.TokenResponse> verifyOtp(api.OtpVerifyIn body) async =>
      api.TokenResponse.fromJson(await fakeCall(() => _backend.otpVerify(body.toJson())));

  @override
  Future<api.TokenResponse> refresh(String refreshToken) async => api.TokenResponse.fromJson(
    await fakeCall(() => _backend.refresh({'refresh_token': refreshToken})),
  );

  @override
  Future<api.TokenResponse> switchRole(String role) async => api.TokenResponse.fromJson(
    await fakeCall(
      () async => _backend.switchRole({'role': role}, token: await _tokens.readAccess()),
    ),
  );

  @override
  Future<void> logout(String refreshToken) =>
      fakeCall(() async => _backend.logout(token: await _tokens.readAccess()));

  @override
  Future<api.MeOut> me() async => api.MeOut.fromJson(
    await fakeCall(() async => _backend.me(token: await _tokens.readAccess())),
  );

  @override
  Future<void> adopt({
    required String access,
    required String refresh,
    required Map<String, Object?> me,
    required String role,
    required String lang,
  }) async {
    await _backend.ensureLoaded();
    _backend.adoptSession(access: access, refresh: refresh, me: me, role: role, lang: lang);
  }
}
