import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

typedef DashboardSession = ({String baseUrl, Map<String, String> cookies});
typedef DashboardCredentials = ({
  String baseUrl,
  String username,
  String password,
});

abstract interface class DashboardSessionStore {
  Future<DashboardSession?> read();
  Future<void> save(DashboardSession session);
  Future<void> clear();
  Future<DashboardCredentials?> readCredentials();
  Future<void> saveCredentials(DashboardCredentials credentials);
  Future<void> clearCredentials();
}

class SecureDashboardSessionStore implements DashboardSessionStore {
  const SecureDashboardSessionStore([
    this._storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.unlocked_this_device,
      ),
    ),
  ]);

  static const _sessionKey = 'hermes.dashboard.session';
  static const _credentialsKey = 'hermes.dashboard.credentials';
  final FlutterSecureStorage _storage;

  @override
  Future<DashboardSession?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final baseUrl = decoded['base_url']?.toString() ?? '';
      final rawCookies = decoded['cookies'];
      if (baseUrl.isEmpty || rawCookies is! Map<String, dynamic>) return null;
      return (
        baseUrl: baseUrl,
        cookies: rawCookies.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(DashboardSession session) => _storage.write(
    key: _sessionKey,
    value: jsonEncode({
      'base_url': session.baseUrl,
      'cookies': session.cookies,
    }),
  );

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);

  @override
  Future<DashboardCredentials?> readCredentials() async {
    final raw = await _storage.read(key: _credentialsKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final baseUrl = decoded['base_url']?.toString() ?? '';
      final username = decoded['username']?.toString() ?? '';
      final password = decoded['password']?.toString() ?? '';
      if (baseUrl.isEmpty || username.isEmpty || password.isEmpty) return null;
      return (baseUrl: baseUrl, username: username, password: password);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveCredentials(DashboardCredentials credentials) =>
      _storage.write(
        key: _credentialsKey,
        value: jsonEncode({
          'base_url': credentials.baseUrl,
          'username': credentials.username,
          'password': credentials.password,
        }),
      );

  @override
  Future<void> clearCredentials() => _storage.delete(key: _credentialsKey);
}
