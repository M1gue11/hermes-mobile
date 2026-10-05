import 'package:freezed_annotation/freezed_annotation.dart';

import 'tool_call.dart';
import 'turn_activity.dart';

part 'chat_message.freezed.dart';

/// Fase de streaming de uma mensagem do assistant (espelha o protótipo):
/// primeiro o raciocínio, depois o texto, depois concluído.
enum ChatPhase { reasoning, writing, done, cancelled, failed }

/// Uma mensagem na conversa.
///
/// É uma `sealed class` (união fechada): uma mensagem OU é do usuário OU do
/// assistant, com campos diferentes. O compilador obriga a tratar os dois casos
/// num `switch` - é o análogo Dart de um union type discriminado (Zod/TS). O
/// freezed gera as subclasses [UserMessage] e [AssistantMessage].
@freezed
sealed class ChatMessage with _$ChatMessage {
  const factory ChatMessage.user({
    required String id,
    required String text,
    required String time,

    /// Turno com papel de usuário que o runtime injetou, e não a pessoa.
    ///
    /// Continua sendo `user` porque é assim que está persistido e é assim que o
    /// modelo o recebeu; o que muda é a apresentação. Ver A23.
    @Default(false) bool scaffolding,
  }) = UserMessage;

  const factory ChatMessage.assistant({
    required String id,
    @Default(ChatPhase.reasoning) ChatPhase phase,
    @Default('') String reasoning,

    /// Prévia de atividade do servidor, nunca raciocínio nativo do modelo.
    @Default('') String activity,

    /// Estado transitório do turno em execução, o kaomoji do `thinking.delta`.
    ///
    /// Vive só enquanto o turno corre: o gateway o substitui a cada chegada e
    /// o apaga com um evento de texto vazio. Por isso ele **não** está em
    /// [activityItems] e a conversa reaberta nunca o reconstrói, que é o que
    /// mantém a timeline ao vivo igual à do histórico.
    @Default('') String thinking,
    String? reasonTime,
    @Default(<ToolCall>[]) List<ToolCall> tools,
    @Default(<TurnActivity>[]) List<TurnActivity> activityItems,
    @Default('') String text,
    String? time,
    String? model,
    String? runId,
    String? error,
  }) = AssistantMessage;
}
