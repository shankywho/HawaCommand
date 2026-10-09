import 'package:hawa_app/features/shell/data/permission_repository_impl.dart';
import 'package:hawa_app/features/shell/domain/app_permission.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Presentation reaches the repository through the application layer (ARCHITECTURE §3).
export 'package:hawa_app/features/shell/data/permission_repository_impl.dart'
    show permissionRepositoryProvider;

part 'permission_controller.g.dart';

/// Status / request / open settings for one permission kind (education screen state).
@riverpod
class PermissionController extends _$PermissionController {
  @override
  Future<PermissionState> build(AppPermission permission) =>
      ref.watch(permissionRepositoryProvider).status(permission);

  Future<PermissionState> request() async {
    final repo = ref.read(permissionRepositoryProvider);
    await repo.markEducationShown(permission);
    final result = await repo.request(permission);
    if (ref.mounted) state = AsyncData(result);
    return result;
  }

  Future<void> openSettings() => ref.read(permissionRepositoryProvider).openSettings();

  Future<void> recheck() async {
    final result = await ref.read(permissionRepositoryProvider).status(permission);
    if (ref.mounted) state = AsyncData(result);
  }
}
