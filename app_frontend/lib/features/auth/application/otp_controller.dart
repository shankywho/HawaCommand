import 'dart:async';

import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/utils/clock.dart';
import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/auth/data/auth_repository_impl.dart';
import 'package:hawa_app/features/auth/domain/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'otp_controller.g.dart';

enum OtpError { invalidPhone, offline, rateLimited, wrongCode, expired, tooMany, other }

class OtpFlowState {
  const OtpFlowState({
    this.request,
    this.resendAt,
    this.sending = false,
    this.verifying = false,
    this.error,
    this.failure,
    this.attemptsLeft,
    this.retryAfter,
  });

  final OtpRequest? request;
  final DateTime? resendAt;
  final bool sending;
  final bool verifying;
  final OtpError? error;
  final Failure? failure;
  final int? attemptsLeft;
  final Duration? retryAfter;

  OtpFlowState copyWith({
    OtpRequest? request,
    DateTime? resendAt,
    bool? sending,
    bool? verifying,
    OtpError? error,
    Failure? failure,
    int? attemptsLeft,
    Duration? retryAfter,
    bool clearError = false,
  }) => OtpFlowState(
    request: request ?? this.request,
    resendAt: resendAt ?? this.resendAt,
    sending: sending ?? this.sending,
    verifying: verifying ?? this.verifying,
    error: clearError ? null : (error ?? this.error),
    failure: clearError ? null : (failure ?? this.failure),
    attemptsLeft: clearError ? null : (attemptsLeft ?? this.attemptsLeft),
    retryAfter: clearError ? null : (retryAfter ?? this.retryAfter),
  );
}

/// Phone + OTP flow (SCREENS A3/A4): request, countdown, verify, failure mapping.
@Riverpod(keepAlive: true)
class OtpController extends _$OtpController {
  @override
  OtpFlowState build() => const OtpFlowState();

  /// 10 digits starting 6–9 (SCREENS A3).
  static bool validNumber(String digits) => RegExp(r'^[6-9]\d{9}$').hasMatch(digits);

  /// Returns true when the code was sent.
  Future<bool> sendCode(String tenDigits) async {
    if (!validNumber(tenDigits)) {
      state = state.copyWith(error: OtpError.invalidPhone);
      return false;
    }
    state = state.copyWith(sending: true, clearError: true);
    try {
      final req = await ref
          .read(authRepositoryProvider)
          .requestOtp(
            phoneE164: '+91$tenDigits',
            lang: ref.read(settingsStoreProvider).language ?? 'hi',
          );
      if (!ref.mounted) return false;
      state = OtpFlowState(
        request: req,
        resendAt: ref.read(appClockProvider).now().add(req.resendAfter),
      );
      return true;
    } on Failure catch (f) {
      if (ref.mounted) {
        state = state.copyWith(sending: false, error: _map(f), failure: f, retryAfter: _retry(f));
      }
      return false;
    }
  }

  Future<bool> resend() async {
    final req = state.request;
    if (req == null) return false;
    return sendCode(req.phoneE164.substring(3));
  }

  /// Returns true when signed in.
  Future<bool> verify(String code) async {
    final req = state.request;
    if (req == null || state.verifying) return false;
    state = state.copyWith(verifying: true, clearError: true);
    try {
      final user = await ref.read(authRepositoryProvider).verifyOtp(request: req, code: code);
      await ref.read(sessionControllerProvider.notifier).completeLogin(user);
      if (ref.mounted) state = const OtpFlowState();
      return true;
    } on Failure catch (f) {
      if (!ref.mounted) return false;
      final left = f.problem?.extra['attempts_left'];
      state = state.copyWith(
        verifying: false,
        error: _map(f),
        failure: f,
        attemptsLeft: left is num ? left.toInt() : null,
        retryAfter: _retry(f),
      );
      return false;
    }
  }

  void reset() => state = const OtpFlowState();

  static OtpError _map(Failure f) => switch (f) {
    NetworkFailure() || SimulatedOfflineFailure() || TimeoutFailure() => OtpError.offline,
    RateLimitedFailure(code: 'otp_attempts_exceeded') => OtpError.tooMany,
    RateLimitedFailure() => OtpError.rateLimited,
    UnauthorizedFailure(code: 'otp_expired') => OtpError.expired,
    UnauthorizedFailure(code: 'otp_invalid') => OtpError.wrongCode,
    ValidationFailure() => OtpError.invalidPhone,
    _ => OtpError.other,
  };

  static Duration? _retry(Failure f) => f is RateLimitedFailure ? f.retryAfter : null;
}
