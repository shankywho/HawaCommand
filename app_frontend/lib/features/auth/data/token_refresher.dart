import 'package:hawa_app/core/storage/secure_token_store.dart';
import 'package:hawa_app/features/auth/data/auth_remote_source.dart';

/// `POST /v1/auth/refresh` for the RefreshInterceptor (tokens rotate; ARCHITECTURE §6.3).
class TokenRefresherImpl {
  TokenRefresherImpl(this._remote, this._tokens);

  final AuthRemoteSource _remote;
  final TokenStore _tokens;

  Future<void> call() async {
    final refresh = await _tokens.readRefresh();
    if (refresh == null) throw StateError('no refresh token');
    final res = await _remote.refresh(refresh);
    await _tokens.saveTokens(access: res.accessToken, refresh: res.refreshToken);
  }
}
