import 'package:dio/dio.dart';
import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/app/env.dart';
import 'package:hawa_app/core/network/dio_provider.dart';
import 'package:hawa_app/core/network/fake/fake_backend_provider.dart';
import 'package:hawa_app/core/network/hawa_api_provider.dart';
import 'package:hawa_app/core/network/interceptors/problem_json_interceptor.dart';
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/auth/data/fake_auth_remote_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_remote_source.g.dart';

/// Auth + Me calls, in generated-client models.
abstract interface class AuthRemoteSource {
  Future<api.OtpRequestOut> requestOtp(api.OtpRequestIn body);

  Future<api.TokenResponse> verifyOtp(api.OtpVerifyIn body);

  Future<api.TokenResponse> refresh(String refreshToken);

  Future<api.TokenResponse> switchRole(String role);

  Future<void> logout(String refreshToken);

  Future<api.MeOut> me();

  /// Fake mode only: re-attach a still-valid session after an app restart.
  Future<void> adopt({
    required String access,
    required String refresh,
    required Map<String, Object?> me,
    required String role,
    required String lang,
  });
}

class HttpAuthRemoteSource implements AuthRemoteSource {
  HttpAuthRemoteSource(this._api, this._bareApi);

  final api.HawaApi _api;

  /// On the bare Dio: the refresh call must not loop through the auth/refresh interceptors.
  final api.HawaApi _bareApi;

  Future<T> _run<T>(Future<Response<T>> Function() call) async {
    try {
      final res = await call();
      return res.data as T;
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<api.OtpRequestOut> requestOtp(api.OtpRequestIn body) =>
      _run(() => _api.getAuthApi().authOtpRequest(otpRequestIn: body));

  @override
  Future<api.TokenResponse> verifyOtp(api.OtpVerifyIn body) =>
      _run(() => _api.getAuthApi().authOtpVerify(otpVerifyIn: body));

  @override
  Future<api.TokenResponse> refresh(String refreshToken) => _run(
    () => _bareApi.getAuthApi().authRefresh(refreshIn: api.RefreshIn(refreshToken: refreshToken)),
  );

  @override
  Future<api.TokenResponse> switchRole(String role) => _run(
    () => _api.getAuthApi().authSwitchRole(
      switchRoleIn: api.SwitchRoleIn(
        role: api.UserRole.values.firstWhere(
          (r) => r.value == role,
          orElse: () => api.UserRole.unknownDefaultOpenApi,
        ),
      ),
    ),
  );

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _api.getAuthApi().authLogout(logoutIn: api.LogoutIn(refreshToken: refreshToken));
    } on DioException catch (e) {
      throw failureOf(e);
    }
  }

  @override
  Future<api.MeOut> me() => _run(() => _api.getMeApi().meGet());

  @override
  Future<void> adopt({
    required String access,
    required String refresh,
    required Map<String, Object?> me,
    required String role,
    required String lang,
  }) async {}
}

/// Fake (fixtures + OTP 123456) when `USE_FAKE_API` or `FAKE_FEATURES` lists `auth`.
@Riverpod(keepAlive: true)
AuthRemoteSource authRemoteSource(Ref ref) => Env.isFake('auth')
    ? FakeAuthRemoteSource(ref.watch(fakeBackendProvider), ref.watch(tokenStoreProvider))
    : HttpAuthRemoteSource(
        ref.watch(hawaApiProvider),
        api.HawaApi(dio: ref.watch(bareDioProvider), interceptors: const []),
      );
