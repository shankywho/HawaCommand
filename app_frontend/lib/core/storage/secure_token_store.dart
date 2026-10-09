import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hawa_app/core/utils/ids.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_token_store.g.dart';

/// Tokens, user id, cached `/v1/me` and the install id. Android Keystore-backed; tokens are
/// kept in memory too and never logged (ARCHITECTURE §18).
abstract interface class TokenStore {
  Future<String?> readAccess();

  Future<String?> readRefresh();

  /// From the JWT `exp` claim.
  Future<DateTime?> readAccessExpiry();

  Future<void> saveTokens({required String access, required String refresh});

  Future<String?> readUserId();

  Future<void> saveUserId(String userId);

  Future<Map<String, Object?>?> readMe();

  Future<void> saveMe(Map<String, Object?> me);

  /// Stable per install; kept across logouts for support.
  Future<String> installId();

  /// Session expired: tokens go, user id and the outbox stay (OFFLINE_AND_SYNC §10).
  Future<void> clearTokens();

  /// Logout wipe.
  Future<void> clearAll();
}

/// Reads `exp` from a JWT payload (no signature check: the server is the authority).
DateTime? jwtExpiry(String? token) {
  if (token == null) return null;
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final exp = (jsonDecode(payload) as Map)['exp'];
    return exp is num ? DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true) : null;
  } on FormatException {
    return null;
  }
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _access = 'access_token';
  static const _refresh = 'refresh_token';
  static const _user = 'user_id';
  static const _me = 'me_json';
  static const _install = 'install_id';

  String? _accessCache;
  bool _accessLoaded = false;

  @override
  Future<String?> readAccess() async {
    if (!_accessLoaded) {
      _accessCache = await _storage.read(key: _access);
      _accessLoaded = true;
    }
    return _accessCache;
  }

  @override
  Future<String?> readRefresh() => _storage.read(key: _refresh);

  @override
  Future<DateTime?> readAccessExpiry() async => jwtExpiry(await readAccess());

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _accessCache = access;
    _accessLoaded = true;
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  @override
  Future<String?> readUserId() => _storage.read(key: _user);

  @override
  Future<void> saveUserId(String userId) => _storage.write(key: _user, value: userId);

  @override
  Future<Map<String, Object?>?> readMe() async {
    final raw = await _storage.read(key: _me);
    if (raw == null) return null;
    return (jsonDecode(raw) as Map).cast<String, Object?>();
  }

  @override
  Future<void> saveMe(Map<String, Object?> me) => _storage.write(key: _me, value: jsonEncode(me));

  @override
  Future<String> installId() async {
    final existing = await _storage.read(key: _install);
    if (existing != null) return existing;
    final id = newId();
    await _storage.write(key: _install, value: id);
    return id;
  }

  @override
  Future<void> clearTokens() async {
    _accessCache = null;
    _accessLoaded = true;
    await _storage.delete(key: _access);
    await _storage.delete(key: _refresh);
  }

  @override
  Future<void> clearAll() async {
    await clearTokens();
    await _storage.delete(key: _user);
    await _storage.delete(key: _me);
  }
}

/// Test and fallback implementation.
class InMemoryTokenStore implements TokenStore {
  final Map<String, String> _values = {};
  Map<String, Object?>? _meJson;

  @override
  Future<String?> readAccess() async => _values['access'];

  @override
  Future<String?> readRefresh() async => _values['refresh'];

  @override
  Future<DateTime?> readAccessExpiry() async => jwtExpiry(_values['access']);

  @override
  Future<void> saveTokens({required String access, required String refresh}) async {
    _values['access'] = access;
    _values['refresh'] = refresh;
  }

  @override
  Future<String?> readUserId() async => _values['user'];

  @override
  Future<void> saveUserId(String userId) async => _values['user'] = userId;

  @override
  Future<Map<String, Object?>?> readMe() async => _meJson;

  @override
  Future<void> saveMe(Map<String, Object?> me) async => _meJson = me;

  @override
  Future<String> installId() async => _values.putIfAbsent('install', newId);

  @override
  Future<void> clearTokens() async {
    _values
      ..remove('access')
      ..remove('refresh');
  }

  @override
  Future<void> clearAll() async {
    await clearTokens();
    _values.remove('user');
    _meJson = null;
  }
}

@Riverpod(keepAlive: true)
TokenStore tokenStore(Ref ref) => SecureTokenStore(const FlutterSecureStorage());
