import 'package:freezed_annotation/freezed_annotation.dart';

import 'approval_request.dart';
import 'clarify_request.dart';
import 'run.dart';
import 'tool_call.dart';

part 'run_event.freezed.dart';

/// Um evento incremental do stream SSE de uma run (`/v1/runs/{id}/events`).
///
/// A doc do Hermes NÃO fixa o schema exato desses eventos (só cita "deltas de
/// texto, progresso de tool e eventos de ciclo de vida"), então este union é
/// deliberadamente defensivo: o parser no data layer mapeia o que reconhece e
/// joga o resto em [RunUnknown], preservando o `type` e o payload cru. Assim a
/// UI nunca quebra com um evento novo do servidor.
@freezed
sealed class RunEvent with _$RunEvent {
  /// Prévia sintética de atividade do servidor; não é chain-of-thought.
  const factory RunEvent.activityPreview(String text) = RunActivityPreview;

  /// Raciocínio nativo incremental emitido pelo provider via gateway TUI.
  const factory RunEvent.reasoningDelta(String text) = RunReasoningDelta;

  /// Estado transitório de execução do gateway TUI, o `thinking.delta` com
  /// kaomoji (`(´･_･`) reasoning...`).
  ///
  /// Não é conteúdo do turno e **não entra no histórico**: o gateway substitui
  /// o estado a cada chegada e manda o mesmo evento com texto vazio para
  /// limpá-lo. Tratar cada chegada como bloco empilhava quatro kaomojis
  /// permanentes na timeline ao vivo que a conversa reaberta não tinha.
  const factory RunEvent.thinkingState(String text) = RunThinkingState;

  /// Pedaço do texto final do assistant a ser anexado.
  const factory RunEvent.delta(String text) = RunTextDelta;

  /// Progresso de uma tool call (entra na timeline, separada do texto).
  const factory RunEvent.toolProgress(ToolCall tool) = RunToolProgress;

  /// O servidor quer executar algo perigoso e está **bloqueado** esperando
  /// resposta. A run fica em `waiting_for_approval` até um gesto explícito.
  const factory RunEvent.approvalRequest(ApprovalRequest request) =
      RunApprovalRequest;

  /// A aprovação foi resolvida (por este app ou por outro cliente da mesma run).
  const factory RunEvent.approvalResolved(ApprovalChoice choice) =
      RunApprovalResolved;

  /// O agente precisa de uma resposta explícita antes de continuar.
  const factory RunEvent.clarifyRequest(ClarifyRequest request) =
      RunClarifyRequest;

  /// A pergunta interativa foi respondida por este ou por outro cliente.
  const factory RunEvent.clarifyResolved() = RunClarifyResolved;

  /// Mudança de estado do ciclo de vida da run.
  const factory RunEvent.status(RunStatus status) = RunStatusEvent;

  /// Run concluída com sucesso.
  const factory RunEvent.completed({String? output}) = RunCompleted;

  /// Run falhou.
  const factory RunEvent.failed({String? error}) = RunFailed;

  /// Qualquer evento não reconhecido (forward-compat).
  const factory RunEvent.unknown(String type, Map<String, dynamic> data) =
      RunUnknown;
}
