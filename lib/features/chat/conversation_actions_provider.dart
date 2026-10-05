import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/conversation.dart';
import 'chat_drafts_provider.dart';
import 'conversations_provider.dart';
import 'launch_provider.dart';

part 'conversation_actions_provider.g.dart';

/// Ações mutáveis de sessão. Mantém REST fora dos widgets e atualiza a lista.
@Riverpod(keepAlive: true)
class ConversationActions extends _$ConversationActions {
  @override
  FutureOr<void> build() {}

  Future<Conversation> rename(String sessionId, String title) async {
    final conversation = await ref
        .read(hermesRepositoryProvider)
        .updateConversation(sessionId, title: title);
    ref.invalidate(conversationFeedProvider);
    return conversation;
  }

  Future<Conversation> fork(String sessionId, {String? title}) async {
    final conversation = await ref
        .read(hermesRepositoryProvider)
        .forkConversation(sessionId, title: title);
    ref.invalidate(conversationFeedProvider);
    return conversation;
  }

  Future<void> delete(String sessionId) async {
    await ref.read(hermesRepositoryProvider).deleteConversation(sessionId);
    ref.read(chatDraftsProvider.notifier).clear(sessionId);
    // A64: apagar a conversa em que o app abriria da próxima vez tem de apagar
    // também a lembrança dela, senão o próximo launch procura um id morto.
    final store = ref.read(lastConversationStoreProvider);
    if ((await store.read())?.id == sessionId) await store.clear();
    ref.invalidate(conversationFeedProvider);
  }
}
