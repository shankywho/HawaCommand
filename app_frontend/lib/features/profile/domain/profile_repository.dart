import 'package:hawa_app/features/profile/domain/profile.dart';

/// The signed-in user's profile, from the cached `GET /v1/me` (works offline).
// One method on purpose: the screen is read-only; tests swap the implementation.
// ignore: one_member_abstracts
abstract interface class ProfileRepository {
  /// Null when no user is cached (signed out).
  Future<Profile?> load();
}
