import 'package:hawa_app/features/auth/domain/app_user.dart';

class OtpRequest {
  const OtpRequest({required this.phoneE164, required this.resendAfter, this.requestId});

  final String phoneE164;
  final Duration resendAfter;
  final String? requestId;
}

/// Phone OTP, tokens and the cached `/v1/me` (ARCHITECTURE §21.1).
abstract interface class AuthRepository {
  /// `POST /v1/auth/otp/request` (online only).
  Future<OtpRequest> requestOtp({required String phoneE164, required String lang});

  /// `POST /v1/auth/otp/verify` → tokens in secure storage, `/v1/me` cached. A different user
  /// than the last one triggers the logout wipe first.
  Future<AppUser> verifyOtp({required OtpRequest request, required String code});

  /// Cached session for an offline cold start (no network). Null when signed out.
  Future<AppUser?> restore();

  /// `GET /v1/me` and re-cache.
  Future<AppUser> refreshMe();

  /// `POST /v1/auth/refresh` on a bare Dio (single-flight in the interceptor).
  Future<void> refreshTokens();

  /// `POST /v1/auth/switch-role` (multi-role users).
  Future<void> switchRole(String role);

  /// Best-effort `POST /v1/auth/logout` (3 s timeout); local data is wiped by the caller.
  Future<void> logout();

  Future<bool> hasTokens();
}
