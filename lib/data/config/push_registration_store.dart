import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Estado local do push. [syncedEndpoint] é o endpoint que o servidor já
/// conhece: diferente de [endpoint], falta registrar de novo.
typedef StoredPushRegistration = ({
  String deviceId,
  bool enabled,
  String? endpoint,
  String? p256dh,
  String? auth,
  String? syncedEndpoint,
});

abstract interface class PushRegistrationStore {
  /// Nunca devolve nulo: na primeira leitura cria o id deste aparelho.
  Future<StoredPushRegistration> read();
  Future<void> save(StoredPushRegistration registration);
}

/// Chaves WebPush e endpoint ficam no armazenamento seguro: quem tem o
/// endpoint consegue mandar push para este aparelho.
class SecurePushRegistrationStore implements PushRegistrationStore {
  const SecurePushRegistrationStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const storageKey = 'hermes.push_registration';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredPushRegistration> read() async {
    final raw = await _storage.read(key: storageKey);
    final json = _decode(raw);
    final deviceId = json?['device_id'];
    if (json == null || deviceId is! String || deviceId.length < 8) {
      final fresh = (
        deviceId: newPushDeviceId(),
        enabled: false,
        endpoint: null,
        p256dh: null,
        auth: null,
        syncedEndpoint: null,
      );
      await save(fresh);
      return fresh;
    }
    String? text(String key) =>
        json[key] is String ? json[key] as String : null;
    return (
      deviceId: deviceId,
      enabled: json['enabled'] == true,
      endpoint: text('endpoint'),
      p256dh: text('p256dh'),
      auth: text('auth'),
      syncedEndpoint: text('synced_endpoint'),
    );
  }

  @override
  Future<void> save(StoredPushRegistration registration) => _storage.write(
    key: storageKey,
    value: jsonEncode({
      'version': 1,
      'device_id': registration.deviceId,
      'enabled': registration.enabled,
      'endpoint': registration.endpoint,
      'p256dh': registration.p256dh,
      'auth': registration.auth,
      'synced_endpoint': registration.syncedEndpoint,
    }),
  );

  static Map<String, Object?>? _decode(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? decoded.map((key, value) => MapEntry(key.toString(), value))
          : null;
    } on FormatException {
      return null;
    }
  }
}

/// 128 bits aleatórios em base64url: casa com o formato que o plugin aceita
/// (`[A-Za-z0-9_-]{8,64}`).
String newPushDeviceId([Random? random]) {
  final source = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => source.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}
