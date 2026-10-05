import 'package:hermes_mobile/features/chat/launch_provider.dart';

/// Faz o app nascer na lista, sem a abertura automática de A64.
///
/// Existe para os testes que são **sobre a lista** ou sobre o caminho de entrar
/// nela e tocar numa conversa. Sem esta costura eles dependeriam do
/// armazenamento real do aparelho para decidir onde o app começa, o que os
/// tornaria não determinísticos e faria falharem por um motivo que não é o
/// deles.
class StubChatLaunch implements ChatLaunch {
  var _decidiu = false;

  @override
  bool get decidiu => _decidiu;

  @override
  Future<ChatLaunchOutcome> resolve() async {
    _decidiu = true;
    return ChatLaunchOutcome.ficarNaLista;
  }
}
