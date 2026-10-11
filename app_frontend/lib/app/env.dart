/// Build configuration from `--dart-define-from-file=env/<flavor>.json` (ARCHITECTURE §16).
///
/// Values are compiled into the binary and are not secrets. Defaults describe a dev build in fake
/// mode, so a plain `flutter run --flavor dev` still works without a define file.
abstract final class Env {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const wsUrl = String.fromEnvironment('WS_URL', defaultValue: 'ws://10.0.2.2:8000/v1/ws');
  static const useFakeApi = bool.fromEnvironment('USE_FAKE_API', defaultValue: true);
  static const fakeFeatures = String.fromEnvironment('FAKE_FEATURES');

  /// Features that always call the real backend, even with `USE_FAKE_API=true` (e.g. `air_map`,
  /// whose endpoints the backend already serves while the field endpoints are still proposed).
  static const realFeatures = String.fromEnvironment(
    'REAL_FEATURES',
    defaultValue: 'air_map,citizen_air,alerts,school_forecast',
  );
  static const mapTileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key={key}',
  );
  static const mapApiKey = String.fromEnvironment('MAP_API_KEY');

  /// Keyless street basemap used until a MapTiler key is set (Esri World Street Map raster).
  /// Never the OSM Foundation tile servers (ARCHITECTURE §12). Demo use; production needs a
  /// keyed plan.
  static const mapFallbackTileUrl = String.fromEnvironment(
    'MAP_FALLBACK_TILE_URL',
    defaultValue:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
  );
  static const mapFallbackAttribution = String.fromEnvironment(
    'MAP_FALLBACK_ATTRIBUTION',
    defaultValue: 'Tiles © Esri · Esri, HERE, Garmin, OpenStreetMap contributors',
  );

  /// Public road router (OSRM) for the citizen clean-route planner: `{profile}` is car, bike or foot.
  static const routingUrl = String.fromEnvironment(
    'ROUTING_URL',
    defaultValue: 'https://routing.openstreetmap.de/routed-{profile}/route/v1/driving',
  );

  /// Place search (Photon) for the clean-route planner.
  static const geocodingUrl = String.fromEnvironment(
    'GEOCODING_URL',
    defaultValue: 'https://photon.komoot.io/api/',
  );
  static const mapAttribution = String.fromEnvironment(
    'MAP_ATTRIBUTION',
    defaultValue: '© MapTiler © OpenStreetMap contributors',
  );
  /// FCM topic every install subscribes to; the backend sends broadcast alerts to it
  /// (`HAWA_FCM_TOPIC`, default `hawa-alerts`).
  static const fcmTopic = String.fromEnvironment('FCM_TOPIC', defaultValue: 'hawa-alerts');
  static const crashReporting = bool.fromEnvironment('CRASH_REPORTING');
  static const logLevel = String.fromEnvironment('LOG_LEVEL', defaultValue: 'info');
  static const showDevTools = bool.fromEnvironment('SHOW_DEV_TOOLS', defaultValue: true);

  static Set<String> get fakeFeatureSet => _set(fakeFeatures);

  static Set<String> get realFeatureSet => _set(realFeatures);

  static Set<String> _set(String csv) => {
    for (final f in csv.split(','))
      if (f.trim().isNotEmpty) f.trim(),
  };

  /// Whether [feature] (a `lib/features/<name>` folder name) uses its fake remote source.
  static bool isFake(String feature) =>
      !realFeatureSet.contains(feature) && (useFakeApi || fakeFeatureSet.contains(feature));

  /// True when any feature runs on the in-app fake backend.
  static bool get anyFake => useFakeApi || fakeFeatureSet.isNotEmpty;

  /// A MapTiler key is optional: without one the map shows a plain background (§12.4).
  static bool get hasMapKey => mapApiKey.isNotEmpty && !mapApiKey.startsWith('replace-');

  static String get resolvedTileUrl => mapTileUrl.replaceAll('{key}', mapApiKey);

  /// The MapTiler URL with a key, else the keyless fallback basemap.
  static String get basemapUrl => hasMapKey ? resolvedTileUrl : mapFallbackTileUrl;

  static String get basemapAttribution => hasMapKey ? mapAttribution : mapFallbackAttribution;

  /// Startup validation: the names of required keys that are empty.
  static List<String> missingKeys() => [
    if (flavor.isEmpty) 'FLAVOR',
    if (!useFakeApi && apiBaseUrl.isEmpty) 'API_BASE_URL',
    if (!useFakeApi && wsUrl.isEmpty) 'WS_URL',
    if (mapTileUrl.isEmpty) 'MAP_TILE_URL',
  ];

  static bool get isProd => flavor == 'prod';
}
