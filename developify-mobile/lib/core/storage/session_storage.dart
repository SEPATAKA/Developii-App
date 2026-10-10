import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<String?> read();
  Future<void> write(String value);
}

final class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage(this.storage);
  final FlutterSecureStorage storage;
  static const _key = 'developify.mock.session.v1';
  @override
  Future<String?> read() => storage.read(key: _key);
  @override
  Future<void> write(String value) => storage.write(key: _key, value: value);
}
