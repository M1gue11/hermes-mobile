import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_drafts_provider.g.dart';

/// Rascunhos efêmeros separados pela sessão durável da conversa.
///
/// O provider fica vivo enquanto o processo do app existir, mas não grava em
/// disco. A tela escreve com `ref.read`, portanto cada tecla não notifica nem
/// reconstrói a thread de mensagens.
@Riverpod(keepAlive: true)
class ChatDrafts extends _$ChatDrafts {
  @override
  Map<String, String> build() => const {};

  String draftFor(String? sessionId) =>
      sessionId == null ? '' : state[sessionId] ?? '';

  void update(String? sessionId, String value) {
    if (sessionId == null) return;
    if (value.isEmpty) {
      clear(sessionId);
      return;
    }
    state = {...state, sessionId: value};
  }

  void clear(String sessionId) {
    if (!state.containsKey(sessionId)) return;
    state = {...state}..remove(sessionId);
  }
}
