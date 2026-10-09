import 'package:hawa_app/features/site/domain/site_score.dart';

/// The site manager's own site (SCREENS M1). Stale-while-revalidate over `cached_payloads`.
abstract interface class SiteRepository {
  /// The cached site (null until the first successful fetch). Emits on every refresh.
  Stream<SiteSnapshot?> watch();

  /// Fetches `GET /v1/sites/me` and replaces the cache. Throws a typed `Failure` on error and
  /// keeps the cache.
  Future<void> refresh();
}
