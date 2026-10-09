import 'package:hawa_app/features/air_map/domain/air_data.dart';

// Repository interface (ARCHITECTURE §3): presentation depends on this, not on the impl.
abstract interface class AirMapRepository {
  /// Whatever is cached, any age (no network); null on first run.
  Future<AirMapData?> cached();

  /// True when every layer is younger than its TTL.
  Future<bool> isFresh();

  /// Cached layers while fresh, else the backend; falls back to the cache (flagged) when the backend
  /// is unreachable. Throws only when there is nothing cached.
  Future<AirMapData> load({bool force = false});
}
