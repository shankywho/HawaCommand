import 'package:hawa_app/app/l10n/gen/app_localizations.dart';
import 'package:hawa_app/core/errors/failure.dart';

extension FailureMessage on Failure {
  /// Localized, field-friendly copy. Never the server's raw `detail`.
  String message(AppLocalizations l10n) => switch (this) {
    NetworkFailure() || SimulatedOfflineFailure() => l10n.failureNetwork,
    TimeoutFailure() => l10n.failureTimeout,
    UnauthorizedFailure() => l10n.failureUnauthorized,
    ForbiddenFailure() => l10n.failureForbidden,
    NotFoundFailure() => l10n.failureNotFound,
    ConflictFailure() => l10n.failureConflict,
    ValidationFailure() => l10n.failureValidation,
    RateLimitedFailure(:final retryAfter) => l10n.failureRateLimited(
      ((retryAfter?.inSeconds ?? 60) / 60).ceil().toString(),
    ),
    ServerFailure() => l10n.failureServer,
    UnknownFailure() => l10n.failureUnknown,
  };
}

/// Any thrown object as a [Failure].
Failure asFailure(Object error) => error is Failure ? error : UnknownFailure(error);
