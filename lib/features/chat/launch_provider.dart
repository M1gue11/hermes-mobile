import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config/last_conversation_store.dart';
import '../../domain/models/conversation.dart';
import 'chat_controller.dart';

final lastConversationStoreProvider = Provider<LastConversationStore>(
  (ref) => const SecureLastConversationStore(),
);

/// O que a abertura do app decidiu fazer (A64).
enum ChatLaunchOutcome {
  /// Uma conversa está pronta e o app deve **nascer** dentro dela.
  abrirChat,

  /// Nada foi aberto. A lista é a tela inicial e ela mesma mostra a causa e
  /// oferece tentar de novo, que é o certo quando o servidor não responde.
  ficarNaLista,
}

/// Decide, **antes de existir uma rota**, se o app nasce na conversa ou na
/// lista.
///
/// Decidir depois produzia o efeito que o usuário mediu em 2026-08-15: a lista
/// aparecia e só então o chat deslizava por cima sozinho. Por isso aqui não há
/// nada de rede no caminho comum. A leitura é local, a rota já nasce certa, e a
/// hidratação corre dentro do chat, que tem estado próprio de carregando, de
/// falha e de tentar de novo.
///
/// A decisão vale **uma vez por processo**. Sem essa trava, rebuild, volta de
/// background e reidratação de provider criariam sessão nova; com ela, a regra
/// de abertura nunca vira sequestro de navegação.
class ChatLaunch {
  ChatLaunch(this._ref);

  final Ref _ref;
  Future<ChatLaunchOutcome>? _resolvido;

  /// Já decidiu alguma coisa neste processo.
  bool get decidiu => _resolvido != null;

  Future<ChatLaunchOutcome> resolve() => _resolvido ??= _resolve();

  Future<ChatLaunchOutcome> _resolve() async {
    LastConversation? lugar;
    try {
      lugar = await _ref.read(lastConversationStoreProvider).read();
    } catch (_) {
      // Preferência ilegível não impede abrir o app; segue como primeiro uso.
    }

    final controller = _ref.read(chatControllerProvider.notifier);

    if (lugar != null) {
      // Otimista de propósito: não perguntamos ao servidor se a conversa ainda
      // existe. Se não existir, a hidratação falha dentro do chat, que mostra a
      // falha, oferece tentar de novo e esquece o lugar para o próximo launch.
      // Perguntar antes custaria uma ida à rede na abertura de todo dia para
      // cobrir um caso raro, e era isso que fazia a lista aparecer primeiro.
      unawaited(
        controller.openConversation(
          Conversation(id: lugar.id, title: lugar.title),
        ),
      );
      return ChatLaunchOutcome.abrirChat;
    }

    try {
      await controller.newChat();
      return ChatLaunchOutcome.abrirChat;
    } catch (_) {
      return ChatLaunchOutcome.ficarNaLista;
    }
  }
}

final chatLaunchProvider = Provider<ChatLaunch>(ChatLaunch.new);
