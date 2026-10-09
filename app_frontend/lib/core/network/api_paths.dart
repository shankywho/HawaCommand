/// Path predicates used by the interceptors.
abstract final class ApiPaths {
  static const refresh = '/v1/auth/refresh';

  /// Auth endpoints never trigger a refresh-and-replay.
  static bool isAuthCall(String path) => path.contains('/v1/auth/');

  /// Mutating methods carry an `Idempotency-Key` (API.md §1.7).
  static bool isMutating(String method) =>
      const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(method.toUpperCase());
}
