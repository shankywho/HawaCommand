import 'dart:async';

import 'package:hawa_api/hawa_api.dart' as api;
import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/core/storage/settings_store.dart';
import 'package:hawa_app/core/storage/wipe_service.dart';
import 'package:hawa_app/features/auth/data/auth_remote_source.dart';
import 'package:hawa_app/features/auth/data/token_refresher.dart';
import 'package:hawa_app/features/auth/domain/app_user.dart';
import 'package:hawa_app/features/auth/domain/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_impl.g.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.remote,
    required this.tokens,
    required this.wipe,
    required this.settings,
  });

  final AuthRemoteSource remote;
  final TokenStore tokens;
  final WipeService wipe;
  final SettingsStore settings;

  @override
  Future<OtpRequest> requestOtp({required String phoneE164, required String lang}) async {
    final res = await remote.requestOtp(
      api.OtpRequestIn(
        phoneE164: phoneE164,
        channel: api.OtpChannel.sms,
        lang: lang == 'hi' ? api.Lang.hi : api.Lang.en,
      ),
    );
    return OtpRequest(
      phoneE164: phoneE164,
      resendAfter: Duration(seconds: res.resendAfter),
      requestId: res.requestId,
    );
  }

  @override
  Future<AppUser> verifyOtp({required OtpRequest request, required String code}) async {
    final res = await remote.verifyOtp(
      api.OtpVerifyIn(
        phoneE164: request.phoneE164,
        code: code,
        requestId: request.requestId,
        installId: await tokens.installId(),
        deviceLabel: 'HawaCommand field app',
      ),
    );
    final previous = await tokens.readUserId();
    if (previous != null && previous != res.user.id) {
      // A different user on a shared phone: wipe before anything loads (OFFLINE_AND_SYNC §10).
      await wipe.wipeAll();
    }
    await tokens.saveTokens(access: res.accessToken, refresh: res.refreshToken);
    await tokens.saveUserId(res.user.id);
    try {
      return await refreshMe();
    } on Object {
      final user = AppUser(
        id: res.user.id,
        displayName: res.user.displayName,
        roles: [
          for (final r in res.user.roles ?? [res.user.role]) r.value,
        ],
        lang: res.user.lang.value,
        assetIds: res.user.assetIds ?? const [],
        wardIds: res.user.wards ?? const [],
        schoolId: res.user.schoolId,
        siteId: res.user.siteId,
        phoneE164: request.phoneE164,
        isSimulated: res.user.isSimulated,
      );
      await tokens.saveMe(user.toJson());
      return user;
    }
  }

  @override
  Future<AppUser?> restore() async {
    if (!await hasTokens()) return null;
    final cached = await tokens.readMe();
    if (cached == null) return null;
    final user = AppUser.fromJson(cached);
    final access = await tokens.readAccess();
    final refresh = await tokens.readRefresh();
    if (access != null && refresh != null) {
      await remote.adopt(
        access: access,
        refresh: refresh,
        me: _meJsonForAdopt(user),
        role: settings.activeRole ?? user.roles.first,
        lang: settings.language ?? user.lang,
      );
    }
    return user;
  }

  @override
  Future<AppUser> refreshMe() async {
    final me = await remote.me();
    final user = mapMe(me);
    await tokens.saveMe(user.toJson());
    return user;
  }

  @override
  Future<void> refreshTokens() => TokenRefresherImpl(remote, tokens)();

  @override
  Future<void> switchRole(String role) async {
    final res = await remote.switchRole(role);
    await tokens.saveTokens(access: res.accessToken, refresh: res.refreshToken);
  }

  @override
  Future<void> logout() async {
    final refresh = await tokens.readRefresh();
    if (refresh == null) return;
    try {
      await remote.logout(refresh).timeout(const Duration(seconds: 3));
    } on Object {
      // Best effort: the local wipe happens regardless.
    }
  }

  @override
  Future<bool> hasTokens() async => (await tokens.readRefresh()) != null;

  /// hawa_api `MeOut` → domain user.
  static AppUser mapMe(api.MeOut me) => AppUser(
    id: me.id,
    displayName: me.displayName,
    roles: [
      for (final r in me.roles ?? [me.role]) r.value,
    ],
    lang: me.lang.value,
    wardIds: [for (final w in me.wards ?? const <api.WardRef>[]) w.wardId],
    wardNames: [for (final w in me.wards ?? const <api.WardRef>[]) w.name ?? w.wardId],
    assetIds: me.assetIds ?? const [],
    schoolId: me.school?.schoolId,
    schoolName: me.school?.name,
    schoolNameHi: me.school?.nameHi,
    siteId: me.site?.siteId,
    siteName: me.site?.name,
    phoneE164: me.phoneE164,
    citizenEyes: me.features?.citizenEyes ?? true,
    schoolScheduler: me.features?.schoolScheduler ?? true,
    isSimulated: me.isSimulated,
  );

  static Map<String, Object?> _meJsonForAdopt(AppUser u) => {
    'id': u.id,
    'role': u.roles.first,
    'roles': u.roles,
    'display_name': u.displayName,
    'lang': u.lang,
    'wards': [
      for (var i = 0; i < u.wardIds.length; i++)
        {'ward_id': u.wardIds[i], 'name': i < u.wardNames.length ? u.wardNames[i] : u.wardIds[i]},
    ],
    'asset_ids': u.assetIds,
    'school': u.schoolId == null
        ? null
        : {'school_id': u.schoolId, 'name': u.schoolName, 'name_hi': u.schoolNameHi},
    'site': u.siteId == null ? null : {'site_id': u.siteId, 'name': u.siteName},
    'phone_e164': u.phoneE164,
    'features': {
      'citizen_eyes': u.citizenEyes,
      'school_scheduler': u.schoolScheduler,
      'open_data': true,
    },
    'is_simulated': u.isSimulated,
  };
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
  remote: ref.watch(authRemoteSourceProvider),
  tokens: ref.watch(tokenStoreProvider),
  wipe: ref.watch(wipeServiceProvider),
  settings: ref.watch(settingsStoreProvider),
);
