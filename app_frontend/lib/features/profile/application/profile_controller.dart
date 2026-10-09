import 'package:hawa_app/features/auth/application/session_controller.dart';
import 'package:hawa_app/features/profile/data/profile_repository_impl.dart';
import 'package:hawa_app/features/profile/domain/profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// X5: the signed-in user's profile. Rebuilds when the session's user changes (role switch,
/// `/v1/me` refresh); the data comes from the cached `/v1/me`, so it works offline.
@riverpod
Future<Profile?> profileController(Ref ref) {
  ref.watch(currentUserProvider);
  return ref.watch(profileRepositoryProvider).load();
}
