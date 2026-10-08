import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PushStore {
  Future<Map<String, dynamic>> read();
  Future<void> write(Map<String, dynamic> state);
}

/// Only this namespace is read, including in headless mode. No global secrets.
class SecurePushStore implements PushStore {
  const SecurePushStore();
  static const key = 'hermes.unifiedpush.v1';
  static const _storage = FlutterSecureStorage();
  @override
  Future<Map<String, dynamic>> read() async {
    final raw = await _storage.read(key: key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    return decoded;
  }

  @override
  Future<void> write(Map<String, dynamic> state) =>
      _storage.write(key: key, value: jsonEncode(state));
}
