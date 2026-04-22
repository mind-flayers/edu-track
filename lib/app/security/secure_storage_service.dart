import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: const AndroidOptions(),
  );

  static Future<void> writeSecret(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> readSecret(String key) async {
    return _storage.read(key: key);
  }

  static Future<void> deleteSecret(String key) async {
    await _storage.delete(key: key);
  }
}
