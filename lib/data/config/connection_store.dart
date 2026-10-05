import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/hermes_connection.dart';

abstract interface class ConnectionStore {
  Future<HermesConnection?> read();
  Future<void> save(HermesConnection connection);
  Future<void> clear();
}

/// Persiste a configuração do pareamento no KeyStore Android / Keychain iOS.
class SecureConnectionStore implements ConnectionStore {
  const SecureConnectionStore([this._storage = const FlutterSecureStorage()]);

  static const _baseUrlKey = 'hermes.connection.base_url';
  static const _apiKeyKey = 'hermes.connection.api_key';

  final FlutterSecureStorage _storage;

  @override
  Future<HermesConnection?> read() async {
    final baseUrl = await _storage.read(key: _baseUrlKey);
    final apiKey = await _storage.read(key: _apiKeyKey);
    if (baseUrl == null || apiKey == null) return null;

    final connection = HermesConnection(baseUrl: baseUrl, apiKey: apiKey).normalized();
    return connection.validate() == null ? connection : null;
  }

  @override
  Future<void> save(HermesConnection connection) async {
    final normalized = connection.normalized();
    await _storage.write(key: _baseUrlKey, value: normalized.baseUrl);
    await _storage.write(key: _apiKeyKey, value: normalized.apiKey);
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _baseUrlKey);
    await _storage.delete(key: _apiKeyKey);
  }
}
