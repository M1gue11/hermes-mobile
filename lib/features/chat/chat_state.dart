import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/approval_request.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/clarify_request.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/reasoning_config.dart';

part 'chat_state.freezed.dart';

/// Estado imutável de uma conversa aberta no app.
@freezed
abstract class ChatState with _$ChatState {
  const factory ChatState({
    @Default(<ChatMessage>[]) List<ChatMessage> messages,
    @Default('Nova conversa') String title,
    @Default(false) bool streaming,
    @Default('') String modelId,
    String? modelProvider,
    @Default(ReasoningConfig()) ReasoningConfig reasoning,
    @Default('') String instructions,
    String? sessionId,
    String? runId,

    /// A rota já abriu, mas histórico e eventual turno ativo ainda estão sendo
    /// reconciliados. Nunca deve bloquear a navegação na lista.
    @Default(false) bool openingConversation,
    HermesFailure? conversationLoadFailure,

    /// Aprovação de ferramenta esperando gesto explícito.
    ///
    /// Enquanto não for nulo a run está parada no servidor, com a thread do
    /// agente bloqueada. Nada é aprovado por omissão, e o composer fica fechado:
    /// mandar outra mensagem enquanto o Hermes espera resposta seria confuso.
    ApprovalRequest? pendingApproval,

    /// Última recusa do servidor a uma resposta de aprovação, para a tela poder
    /// dizer o que aconteceu em vez de simplesmente não reagir ao toque.
    String? approvalError,

    /// Pergunta do gateway TUI que bloqueia o turno até resposta explícita.
    ClarifyRequest? pendingClarification,
    String? clarificationError,
  }) = _ChatState;
}
