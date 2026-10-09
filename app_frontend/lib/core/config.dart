/// Build-time and default configuration.
///
/// Override the backend URL at build time:
/// `flutter run --dart-define=HAWA_API_URL=http://192.168.1.20:8000`.
/// It can also be changed at runtime in Settings.
abstract final class AppConfig {
  /// `10.0.2.2` is the Android emulator's alias for the host machine.
  static const defaultApiUrl = String.fromEnvironment(
    'HAWA_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Default vehicle for the driver role (matches the backend fixture).
  static const defaultAssetId = 'T-12';

  static const connectTimeout = Duration(seconds: 4);
  static const receiveTimeout = Duration(seconds: 6);

  /// How often the active-route screen polls for HawaTag spray updates.
  static const sprayPollInterval = Duration(seconds: 5);
}
