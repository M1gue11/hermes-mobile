import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Onde a pessoa estava da última vez.
typedef LastConversation = ({String id, String title});

/// Guarda **o lugar**, não a conversa.
///
/// Id e título, e nada mais: mensagens, modelo e estado continuam vindo do
/// servidor, que é a fonte autoritativa, e o aparelho não vira uma segunda
/// cópia da conversa. O título entra porque é o rótulo do lugar, e sem ele a
/// barra do chat abriria vazia esperando a rede; ele é reescrito toda vez que a
/// conversa é aberta, então no máximo fica velho por um instante.
abstract interface class LastConversationStore {
  Future<LastConversation?> read();
  Future<void> save(String sessionId, String title);
  Future<void> clear();
}

/// Usa o mesmo armazenamento seguro já adotado pelo pareamento, pela sessão do
/// Dashboard e pelo vínculo de run ativa.
class SecureLastConversationStore implements LastConversationStore {
  const SecureLastConversationStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const storageKey = 'hermes.last_conversation';
  final FlutterSecureStorage _storage;

  @override
  Future<LastConversation?> read() async {
    final raw = await _storage.read(key: storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final id = decoded['id']?.toString().trim() ?? '';
      if (id.isEmpty) return null;
      return (id: id, title: decoded['title']?.toString() ?? '');
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(String sessionId, String title) {
    final id = sessionId.trim();
    return id.isEmpty
        ? clear()
        : _storage.write(
            key: storageKey,
            value: jsonEncode({'version': 1, 'id': id, 'title': title}),
          );
  }

  @override
  Future<void> clear() => _storage.delete(key: storageKey);
}
