import 'package:hermes_mobile/data/config/last_conversation_store.dart';

/// Guarda o lugar em memória e registra as escritas, para provar que a abertura
/// automática não grava nem cria nada além do necessário.
class MemoryLastConversationStore implements LastConversationStore {
  MemoryLastConversationStore({String? id, String title = '', this.readFailure})
    : value = id == null ? null : (id: id, title: title);

  LastConversation? value;

  /// Erro imposto na leitura, para reproduzir armazenamento indisponível.
  final Object? readFailure;

  final List<LastConversation?> writes = [];

  @override
  Future<LastConversation?> read() async {
    final failure = readFailure;
    if (failure != null) throw failure;
    return value;
  }

  @override
  Future<void> save(String sessionId, String title) async {
    value = (id: sessionId, title: title);
    writes.add(value);
  }

  @override
  Future<void> clear() async {
    value = null;
    writes.add(null);
  }
}
