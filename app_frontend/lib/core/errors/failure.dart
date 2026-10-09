import 'package:hawa_app/core/errors/problem_details.dart';

export 'package:hawa_app/core/errors/problem_details.dart' show FieldError, ProblemDetails;

/// Typed failures surfaced to controllers (ARCHITECTURE §6.4). Presentation maps them to
/// localized copy; the raw server `detail` only appears in the "Details" expander.
sealed class Failure implements Exception {
  const Failure({this.requestId, this.code, this.problem});

  /// Builds a failure from an HTTP status and an optional problem body.
  factory Failure.fromStatus(
    int status, {
    ProblemDetails? problem,
    String? requestId,
    Duration? retryAfter,
  }) {
    final code = problem?.code;
    final rid = requestId ?? problem?.requestId;
    return switch (status) {
      401 => UnauthorizedFailure(requestId: rid, code: code, problem: problem),
      403 => ForbiddenFailure(requestId: rid, code: code, problem: problem),
      404 || 410 => NotFoundFailure(requestId: rid, code: code ?? 'gone', problem: problem),
      409 => ConflictFailure(
        code: code ?? 'conflict',
        requestId: rid,
        problem: problem,
        retryAfter: retryAfter,
      ),
      400 || 413 || 415 || 422 => ValidationFailure(
        problem?.errors ?? const [],
        status: status,
        requestId: rid,
        code: code,
        problem: problem,
      ),
      408 => TimeoutFailure(requestId: rid),
      429 => RateLimitedFailure(
        retryAfter: retryAfter,
        requestId: rid,
        code: code,
        problem: problem,
      ),
      >= 500 => ServerFailure(status, requestId: rid, code: code, problem: problem),
      _ => UnknownFailure('HTTP $status', requestId: rid),
    };
  }

  /// `X-Request-Id`, shown under "Details" for support.
  final String? requestId;

  /// Normalized problem+json `code`.
  final String? code;
  final ProblemDetails? problem;

  bool get isTransient => false;

  @override
  String toString() => 'Failure(code: $code, requestId: $requestId)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure({super.requestId});

  @override
  bool get isTransient => true;
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.requestId});

  @override
  bool get isTransient => true;
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.requestId, super.code, super.problem});
}

final class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.requestId, super.code, super.problem});
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure({super.requestId, super.code, super.problem});
}

final class ConflictFailure extends Failure {
  const ConflictFailure({
    required String super.code,
    super.requestId,
    super.problem,
    this.retryAfter,
  });

  final Duration? retryAfter;

  Map<String, Object?> get detail => problem?.extra ?? const {};

  /// `409 idempotency_in_progress` with `Retry-After: 1` is retried (backend CACHING §9).
  @override
  bool get isTransient => code == 'idempotency_in_progress';
}

final class ValidationFailure extends Failure {
  const ValidationFailure(
    this.errors, {
    this.status = 422,
    super.requestId,
    super.code,
    super.problem,
  });

  final List<FieldError> errors;
  final int status;
}

final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter, super.requestId, super.code, super.problem});

  final Duration? retryAfter;

  @override
  bool get isTransient => true;
}

final class ServerFailure extends Failure {
  const ServerFailure(this.status, {super.requestId, super.code, super.problem});

  final int status;

  @override
  bool get isTransient => status >= 502 && status <= 504;
}

final class UnknownFailure extends Failure {
  const UnknownFailure(this.cause, {super.requestId});

  final Object cause;
}

/// Fake-mode only: Dev tools "Go offline" (PLAN §6).
final class SimulatedOfflineFailure extends Failure {
  const SimulatedOfflineFailure();

  @override
  bool get isTransient => true;
}
