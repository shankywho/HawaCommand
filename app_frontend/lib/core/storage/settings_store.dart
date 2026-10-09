import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_store.g.dart';

/// Display choice (SCREENS X3). `auto` = outdoor for driver/inspector shells, light otherwise
/// (dark follows the system for non-field roles).
enum DisplayMode {
  auto,
  standard,
  dark,
  outdoor;

  static DisplayMode fromName(String? name) =>
      values.firstWhere((m) => m.name == name, orElse: () => auto);
}

/// shared_preferences wrapper: language, active role, display, data saver, onboarding flags.
/// Nothing sensitive lives here (ARCHITECTURE §9).
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _language = 'language';
  static const _activeRole = 'active_role';
  static const _display = 'display_mode';
  static const _dataSaver = 'data_saver';
  static const _cvd = 'cvd_palette';
  static const _privacyAccepted = 'citizen_privacy_accepted';
  static const _notifPrefs = 'notification_prefs';
  static const _lastVersion = 'last_app_version';
  static const _fakeOffline = 'dev_fake_offline';
  static const _shift = 'active_shift';
  static const _area = 'citizen_manual_area';
  static const _educationPrefix = 'perm_education_';

  String? get language => _prefs.getString(_language);

  Future<void> setLanguage(String lang) => _prefs.setString(_language, lang);

  String? get activeRole => _prefs.getString(_activeRole);

  Future<void> setActiveRole(String? role) =>
      role == null ? _prefs.remove(_activeRole) : _prefs.setString(_activeRole, role);

  DisplayMode get displayMode => DisplayMode.fromName(_prefs.getString(_display));

  Future<void> setDisplayMode(DisplayMode mode) => _prefs.setString(_display, mode.name);

  bool get dataSaver => _prefs.getBool(_dataSaver) ?? false;

  Future<void> setDataSaver({required bool on}) => _prefs.setBool(_dataSaver, on);

  bool get cvdPalette => _prefs.getBool(_cvd) ?? false;

  Future<void> setCvdPalette({required bool on}) => _prefs.setBool(_cvd, on);

  bool get privacyAccepted => _prefs.getBool(_privacyAccepted) ?? false;

  Future<void> setPrivacyAccepted() => _prefs.setBool(_privacyAccepted, true);

  bool educationShown(String kind) => _prefs.getBool('$_educationPrefix$kind') ?? false;

  Future<void> setEducationShown(String kind) => _prefs.setBool('$_educationPrefix$kind', true);

  Map<String, bool> get notificationPrefs {
    final raw = _prefs.getString(_notifPrefs);
    if (raw == null) return const {};
    return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v == true));
  }

  Future<void> setNotificationPrefs(Map<String, bool> prefs) =>
      _prefs.setString(_notifPrefs, jsonEncode(prefs));

  String? get lastAppVersion => _prefs.getString(_lastVersion);

  Future<void> setLastAppVersion(String v) => _prefs.setString(_lastVersion, v);

  bool get fakeOffline => _prefs.getBool(_fakeOffline) ?? false;

  Future<void> setFakeOffline({required bool on}) => _prefs.setBool(_fakeOffline, on);

  /// Persisted shift (failure matrix rows 5–6: resume after a kill or reboot).
  Map<String, Object?>? get activeShift {
    final raw = _prefs.getString(_shift);
    return raw == null ? null : (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  Future<void> setActiveShift(Map<String, Object?>? shift) =>
      shift == null ? _prefs.remove(_shift) : _prefs.setString(_shift, jsonEncode(shift));

  /// Citizen manual area when location is denied (SCREENS C1).
  Map<String, Object?>? get manualArea {
    final raw = _prefs.getString(_area);
    return raw == null ? null : (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  Future<void> setManualArea(Map<String, Object?>? area) =>
      area == null ? _prefs.remove(_area) : _prefs.setString(_area, jsonEncode(area));

  /// Logout: everything goes except the language choice (OFFLINE_AND_SYNC §10).
  Future<void> clearExceptLanguage() async {
    final lang = language;
    await _prefs.clear();
    if (lang != null) await setLanguage(lang);
  }
}

/// Overridden in bootstrap with the loaded instance (prefs load before the first frame).
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden in bootstrap');

@Riverpod(keepAlive: true)
SettingsStore settingsStore(Ref ref) => SettingsStore(ref.watch(sharedPreferencesProvider));

/// Reactive app-wide display preferences (language, display mode, palette, data saver).
class AppPreferences {
  const AppPreferences({
    required this.language,
    required this.displayMode,
    required this.dataSaver,
    required this.cvdPalette,
  });

  final String? language;
  final DisplayMode displayMode;
  final bool dataSaver;
  final bool cvdPalette;

  bool get languageChosen => language != null;

  /// UI language; Hindi until the user picks (the picker shows both scripts).
  String get lang => language ?? 'hi';

  AppPreferences copyWith({
    String? language,
    DisplayMode? displayMode,
    bool? dataSaver,
    bool? cvdPalette,
  }) => AppPreferences(
    language: language ?? this.language,
    displayMode: displayMode ?? this.displayMode,
    dataSaver: dataSaver ?? this.dataSaver,
    cvdPalette: cvdPalette ?? this.cvdPalette,
  );
}

@Riverpod(keepAlive: true)
class AppPreferencesController extends _$AppPreferencesController {
  @override
  AppPreferences build() {
    final s = ref.watch(settingsStoreProvider);
    return AppPreferences(
      language: s.language,
      displayMode: s.displayMode,
      dataSaver: s.dataSaver,
      cvdPalette: s.cvdPalette,
    );
  }

  Future<void> setLanguage(String lang) async {
    await ref.read(settingsStoreProvider).setLanguage(lang);
    state = state.copyWith(language: lang);
  }

  Future<void> setDisplayMode(DisplayMode mode) async {
    await ref.read(settingsStoreProvider).setDisplayMode(mode);
    state = state.copyWith(displayMode: mode);
  }

  Future<void> setDataSaver({required bool on}) async {
    await ref.read(settingsStoreProvider).setDataSaver(on: on);
    state = state.copyWith(dataSaver: on);
  }

  Future<void> setCvdPalette({required bool on}) async {
    await ref.read(settingsStoreProvider).setCvdPalette(on: on);
    state = state.copyWith(cvdPalette: on);
  }

  /// Re-read after a logout wipe.
  void reload() => ref.invalidateSelf();
}
