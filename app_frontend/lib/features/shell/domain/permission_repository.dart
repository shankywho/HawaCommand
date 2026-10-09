import 'package:hawa_app/features/shell/domain/app_permission.dart';

abstract interface class PermissionRepository {
  Future<PermissionState> status(AppPermission permission);

  /// Shows the system dialog (only after the education screen).
  Future<PermissionState> request(AppPermission permission);

  Future<void> openSettings();

  bool educationShown(AppPermission permission);

  Future<void> markEducationShown(AppPermission permission);
}
