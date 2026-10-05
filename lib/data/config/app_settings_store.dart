import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Forma neutra de armazenamento. Os enums continuam na camada de UI; o store
/// guarda nomes estáveis e deixa cada campo inválido cair no padrão atual.
typedef StoredAppSettings = ({
  String? agentGender,
  String? agentName,
  String? atmosphere,
  bool? chronologicalActivity,
  String? spinner,
  String? textSize,
  bool? showActivity,
  String? instructions,
});

abstract interface class AppSettingsStore {
  Future<StoredAppSettings?> read();
  Future<void> save(StoredAppSettings settings);
}

class SecureAppSettingsStore implements AppSettingsStore {
  const SecureAppSettingsStore([this._storage = const FlutterSecureStorage()]);

  static const storageKey = 'hermes.app_settings';
  final FlutterSecureStorage _storage;

  @override
  Future<StoredAppSettings?> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final json = decoded.map((key, value) => MapEntry(key.toString(), value));
      return (
        agentGender: json['agent_gender']?.toString(),
        agentName: json['agent_name']?.toString(),
        atmosphere: json['atmosphere']?.toString(),
        chronologicalActivity: json['chronological_activity'] is bool
            ? json['chronological_activity'] as bool
            : null,
        spinner: json['spinner']?.toString(),
        textSize: json['text_size']?.toString(),
        showActivity: json['show_activity'] is bool
            ? json['show_activity'] as bool
            : null,
        instructions: json['instructions']?.toString(),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(StoredAppSettings settings) => _storage.write(
    key: storageKey,
    value: jsonEncode({
      'version': 2,
      'agent_gender': settings.agentGender,
      'agent_name': settings.agentName,
      'atmosphere': settings.atmosphere,
      'chronological_activity': settings.chronologicalActivity,
      'spinner': settings.spinner,
      'text_size': settings.textSize,
      'show_activity': settings.showActivity,
      'instructions': settings.instructions,
    }),
  );
}
