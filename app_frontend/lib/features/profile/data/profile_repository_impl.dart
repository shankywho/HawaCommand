import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/auth/domain/app_user.dart';
import 'package:hawa_app/features/profile/domain/profile.dart';
import 'package:hawa_app/features/profile/domain/profile_repository.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository_impl.g.dart';

/// Reads the cached `/v1/me` (secure storage, written by the auth feature on login and on every
/// refresh) plus the app version and install id. Only the masked phone leaves this class.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.tokens, required this.appVersion});

  final TokenStore tokens;

  /// "0.1.0+3" (package_info_plus in the app; fixed in tests).
  final Future<String> Function() appVersion;

  static final _log = Logger('profile');

  @override
  Future<Profile?> load() async {
    final cached = await tokens.readMe();
    if (cached == null) return null;
    final AppUser user;
    try {
      user = AppUser.fromJson(cached);
    } on Object catch (e) {
      _log.warning('cached user unreadable', e);
      return null;
    }
    return toProfile(user, appVersion: await appVersion(), installId: await tokens.installId());
  }

  static Profile toProfile(
    AppUser user, {
    required String appVersion,
    required String installId,
  }) => Profile(
    name: user.displayName,
    maskedPhone: PhoneMask.mask(user.phoneE164),
    roles: user.roles,
    wards: user.wardNames.isNotEmpty ? user.wardNames : user.wardIds,
    appVersion: appVersion,
    installId: installId,
    isSimulated: user.isSimulated,
  );

  /// package_info_plus version + build number; "—" when the platform cannot tell.
  static Future<String> platformVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.buildNumber.isEmpty ? info.version : '${info.version}+${info.buildNumber}';
    } on Object catch (e) {
      _log.fine('package info unavailable', e);
      return '—';
    }
  }
}

@riverpod
ProfileRepository profileRepository(Ref ref) => ProfileRepositoryImpl(
  tokens: ref.watch(tokenStoreProvider),
  appVersion: ProfileRepositoryImpl.platformVersion,
);
