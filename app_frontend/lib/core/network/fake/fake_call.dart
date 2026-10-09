import 'package:hawa_app/core/errors/failure.dart';
import 'package:hawa_app/core/network/fake/fake_backend.dart';

/// Runs a fake-backend call and maps its errors to the same typed failures the HTTP path
/// produces, so controllers cannot tell fake from real.
Future<T> fakeCall<T>(Future<T> Function() body) async {
  try {
    return await body();
  } on FakeNetworkException {
    throw const SimulatedOfflineFailure();
  } on FakeHttpException catch (e) {
    throw Failure.fromStatus(
      e.status,
      problem: ProblemDetails.fromJson(e.toProblem(), fallbackStatus: e.status),
      retryAfter: e.retryAfter == null ? null : Duration(seconds: e.retryAfter!),
    );
  }
}
