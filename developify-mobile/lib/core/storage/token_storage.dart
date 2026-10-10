import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthTokenProvider {
  Future<String?> readToken();
}

abstract interface class TokenStorage implements AuthTokenProvider {
  Future<void> writeToken(String token);
  Future<void> clearToken();
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String token);
  Future<void> clearRefreshToken();
}

final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const _key = 'developify.auth.access_token';
  static const _refreshKey = 'developify.auth.refresh_token';

  @override
  Future<String?> readToken() => _storage.read(key: _key);
  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _key, value: token);
  @override
  Future<void> clearToken() => _storage.delete(key: _key);

  @override
  Future<String?> readRefreshToken() => _storage.read(key: _refreshKey);
  @override
  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);
  @override
  Future<void> clearRefreshToken() => _storage.delete(key: _refreshKey);
}

final class MemoryTokenStorage implements TokenStorage {
  String? _token;
  String? _refresh;
  @override
  Future<String?> readToken() async => _token;
  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }

  @override
  Future<String?> readRefreshToken() async => _refresh;
  @override
  Future<void> writeRefreshToken(String token) async {
    _refresh = token;
  }

  @override
  Future<void> clearRefreshToken() async {
    _refresh = null;
  }
}
