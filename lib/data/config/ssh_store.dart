import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/ssh_target.dart';

/// O que o aparelho guarda sobre a sessão de shell.
///
/// A chave privada mora aqui e **em nenhum outro lugar**: não vai para log,
/// teste, journal, commit nem para a tela. O que a tela mostra é a pública.
abstract interface class SshStore {
  Future<SshTarget?> readTarget();
  Future<void> saveTarget(SshTarget target);

  /// PEM da chave privada, ou `null` quando ainda não há par gerado.
  Future<String?> readPrivateKey();
  Future<void> savePrivateKey(String pem);

  /// Impressão digital fixada do host, no formato `SHA256:...`.
  Future<String?> readHostFingerprint();
  Future<void> saveHostFingerprint(String fingerprint);
  Future<void> forgetHostFingerprint();

  /// Apaga tudo: chave, alvo e impressão digital.
  Future<void> clear();
}

/// Persiste no KeyStore Android / Keychain iOS, como o pareamento do gateway.
class SecureSshStore implements SshStore {
  const SecureSshStore([this._storage = const FlutterSecureStorage()]);

  static const _hostKey = 'hermes.ssh.host';
  static const _portKey = 'hermes.ssh.port';
  static const _userKey = 'hermes.ssh.user';
  static const _privateKeyKey = 'hermes.ssh.private_key';
  static const _fingerprintKey = 'hermes.ssh.host_fingerprint';

  final FlutterSecureStorage _storage;

  @override
  Future<SshTarget?> readTarget() async {
    final host = await _storage.read(key: _hostKey);
    final user = await _storage.read(key: _userKey);
    if (host == null || user == null) return null;
    final port = int.tryParse(await _storage.read(key: _portKey) ?? '') ?? 22;
    final target = normalizeSshTarget((host: host, port: port, user: user));
    return validateSshTarget(target) == null ? target : null;
  }

  @override
  Future<void> saveTarget(SshTarget target) async {
    final normalizado = normalizeSshTarget(target);
    await _storage.write(key: _hostKey, value: normalizado.host);
    await _storage.write(key: _portKey, value: '${normalizado.port}');
    await _storage.write(key: _userKey, value: normalizado.user);
  }

  @override
  Future<String?> readPrivateKey() => _storage.read(key: _privateKeyKey);

  @override
  Future<void> savePrivateKey(String pem) =>
      _storage.write(key: _privateKeyKey, value: pem);

  @override
  Future<String?> readHostFingerprint() => _storage.read(key: _fingerprintKey);

  @override
  Future<void> saveHostFingerprint(String fingerprint) =>
      _storage.write(key: _fingerprintKey, value: fingerprint);

  @override
  Future<void> forgetHostFingerprint() =>
      _storage.delete(key: _fingerprintKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: _hostKey);
    await _storage.delete(key: _portKey);
    await _storage.delete(key: _userKey);
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _fingerprintKey);
  }
}
