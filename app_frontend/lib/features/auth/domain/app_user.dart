import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The signed-in user from `GET /v1/me` (cached for offline cold starts).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required String displayName,

    /// Wire values; `roles[]` is the multi-role contract (CONTRACTS v1.1), else `[role]`.
    required List<String> roles,
    required String lang,
    @Default(<String>[]) List<String> wardIds,
    @Default(<String>[]) List<String> wardNames,
    @Default(<String>[]) List<String> assetIds,
    String? schoolId,
    String? schoolName,
    String? schoolNameHi,
    String? siteId,
    String? siteName,

    /// The user's own phone (shown masked on the profile only).
    String? phoneE164,
    @Default(true) bool citizenEyes,
    @Default(true) bool schoolScheduler,
    @Default(false) bool isSimulated,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, Object?> json) => _$AppUserFromJson(json);
}
