import 'package:hawa_app/core/location/location_service.dart';
import 'package:hawa_app/core/notifications/local_notifications.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:hawa_app/features/shell/domain/permission_repository.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'permission_repository_impl.g.dart';

/// permission_handler for camera and notifications; geolocator for location (while in use only).
class PermissionRepositoryImpl implements PermissionRepository {
  PermissionRepositoryImpl({
    required this.location,
    required this.notifications,
    required this.settings,
  });

  final LocationService location;
  final LocalNotifications notifications;
  final SettingsStore settings;

  @override
  Future<PermissionState> status(AppPermission permission) async => switch (permission) {
    AppPermission.location => _fromLocation(await location.status()),
    AppPermission.camera => _from(await ph.Permission.camera.status),
    AppPermission.notifications => _from(await ph.Permission.notification.status),
  };

  @override
  Future<PermissionState> request(AppPermission permission) async {
    switch (permission) {
      case AppPermission.location:
        return _fromLocation(await location.request());
      case AppPermission.camera:
        return _from(await ph.Permission.camera.request());
      case AppPermission.notifications:
        final granted = await notifications.requestPermission();
        if (granted) return PermissionState.granted;
        return _from(await ph.Permission.notification.status);
    }
  }

  @override
  Future<void> openSettings() async {
    await ph.openAppSettings();
  }

  @override
  bool educationShown(AppPermission permission) => settings.educationShown(permission.name);

  @override
  Future<void> markEducationShown(AppPermission permission) =>
      settings.setEducationShown(permission.name);

  static PermissionState _from(ph.PermissionStatus s) {
    if (s.isGranted || s.isLimited || s.isProvisional) return PermissionState.granted;
    if (s.isPermanentlyDenied || s.isRestricted) return PermissionState.deniedForever;
    return PermissionState.denied;
  }

  static PermissionState _fromLocation(LocationPermissionState s) => switch (s) {
    LocationPermissionState.granted => PermissionState.granted,
    LocationPermissionState.deniedForever => PermissionState.deniedForever,
    LocationPermissionState.denied || LocationPermissionState.serviceOff => PermissionState.denied,
  };
}

@Riverpod(keepAlive: true)
PermissionRepository permissionRepository(Ref ref) => PermissionRepositoryImpl(
  location: ref.watch(locationServiceProvider),
  notifications: ref.watch(localNotificationsProvider),
  settings: ref.watch(settingsStoreProvider),
);
