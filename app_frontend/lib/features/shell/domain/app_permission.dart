/// Runtime permissions the app asks for, each behind an education screen (SCREENS §2).
/// Never background location, SMS, storage, contacts or microphone.
enum AppPermission {
  notifications,
  location,
  camera;

  static AppPermission? fromName(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }
}

enum PermissionState { granted, denied, deniedForever }
