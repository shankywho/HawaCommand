import 'package:hawa_app/core/utils/geo.dart';
import 'package:hawa_app/core/utils/localized_text.dart';
import 'package:hawa_app/features/citizen_air/domain/air_snapshot.dart';
import 'package:hawa_app/features/citizen_air/domain/alert_subscription.dart';

/// Air near me (cache-first, 30 min stale) and the alert subscription (outbox writes).
abstract interface class CitizenAirRepository {
  /// The cached payload for a snapped box; null until the first fetch.
  Stream<CachedAir?> watchAir(GeoBox box);

  /// `GET /open/v1/air?bbox=` with [box] (snapped to the 0.01° grid; never the precise point).
  Future<void> refreshAir(GeoBox box);

  Stream<AlertSubscriptionPrefs?> watchSubscription();

  /// Skipped while a local edit is still waiting in the outbox (the local copy wins).
  Future<void> refreshSubscription();

  /// Optimistic cache write + outbox `profile_update` (latest wins), in one transaction.
  Future<void> saveSubscription(AlertSubscriptionPrefs prefs);

  /// The place name of the cached cell around [point], if C1 has fetched it.
  Future<LocalizedText?> placeFor(GeoPoint point);
}
