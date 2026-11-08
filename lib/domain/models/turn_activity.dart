import 'package:freezed_annotation/freezed_annotation.dart';

import 'subagent_run.dart';
import 'tool_call.dart';

export 'subagent_run.dart';

part 'turn_activity.freezed.dart';

/// Um acontecimento apresentável dentro de um turno do Hermes.
///
/// A união mantém a semântica que a fonte realmente oferece: prévia de
/// atividade da Runs API, raciocínio nativo quando persistido e chamada de
/// ferramenta. A ordem da lista é a ordem observada pelo cliente.
@freezed
sealed class TurnActivity with _$TurnActivity {
  /// Assistant speech sealed before the next tool/response segment.
  const factory TurnActivity.commentary({
    required String id,
    required String text,
    int? rowId,
  }) = TurnCommentary;

  const factory TurnActivity.activity({
    required String id,
    required String text,
  }) = TurnActivityPreview;

  const factory TurnActivity.reasoning({
    required String id,
    required String text,
  }) = TurnReasoning;

  const factory TurnActivity.tool({
    required String id,
    required ToolCall tool,
  }) = TurnToolActivity;

  /// Agente delegado pelo turno (B9). Agrega os frames `subagent.*` num bloco
  /// só, que nunca vira fala do assistant.
  const factory TurnActivity.subagent({
    required String id,
    required SubagentRun run,
  }) = TurnSubagentActivity;
}

/// Agrega um frame `subagent.*` no bloco do agente correspondente, criando-o
/// na posição em que apareceu. Um início para uma chave já encerrada abre um
/// bloco novo: emissores antigos reusam `task_index` entre delegações.
List<TurnActivity> applySubagentEvent(
  List<TurnActivity> current,
  SubagentEvent event, {
  required String blockId,
}) {
  final target = current.lastIndexWhere(
    (item) =>
        item is TurnSubagentActivity &&
        item.run.key == event.key &&
        !(event.opensRun && item.run.finished),
  );
  if (target < 0) {
    final run = SubagentRun(key: event.key).apply(event);
    return [...current, TurnActivity.subagent(id: blockId, run: run)];
  }
  final updated = [...current];
  final existing = updated[target] as TurnSubagentActivity;
  updated[target] = TurnActivity.subagent(
    id: existing.id,
    run: existing.run.apply(event),
  );
  return updated;
}

/// Acrescenta uma chamada nova ou atualiza a chamada aberta correspondente.
///
/// Replica a correlação defensiva da Runs API: id quando existir; sem id,
/// aberturas sempre criam item e conclusões fecham a abertura mais antiga do
/// mesmo nome. Atualizar preserva a posição cronológica do item.
List<TurnActivity> applyTurnToolEvent(
  List<TurnActivity> current,
  ToolCall event, {
  required String blockId,
}) {
  final target = _toolTarget(current, event);
  if (target < 0) {
    return [...current, TurnActivity.tool(id: blockId, tool: event)];
  }

  final updated = [...current];
  final existing = (updated[target] as TurnToolActivity).tool;
  updated[target] = TurnActivity.tool(
    id: (updated[target] as TurnToolActivity).id,
    tool: event.copyWith(
      id: event.id ?? existing.id,
      arg: event.arg.isEmpty ? existing.arg : event.arg,
      detail: event.detail ?? existing.detail,
      output: event.output ?? existing.output,
      duration: event.duration ?? existing.duration,
      risk: event.risk ?? existing.risk,
      outputRedacted: event.outputRedacted || existing.outputRedacted,
    ),
  );
  return updated;
}

/// Encerra ferramentas e agentes delegados que ficaram abertos quando a run
/// terminou. Sem o `subagent.complete`, o desfecho do agente é desconhecido:
/// em turno bem-sucedido fica concluído, senão interrompido.
List<TurnActivity> settleTurnTools(
  List<TurnActivity> current, {
  bool failed = false,
}) => [
  for (final item in current)
    switch (item) {
      TurnToolActivity(:final id, :final tool)
          when tool.status == ToolStatus.running =>
        TurnActivity.tool(
          id: id,
          tool: tool.copyWith(
            status: failed ? ToolStatus.error : ToolStatus.done,
          ),
        ),
      TurnSubagentActivity(:final id, :final run) when !run.finished =>
        TurnActivity.subagent(
          id: id,
          run: run.copyWith(
            phase: failed ? SubagentPhase.interrupted : SubagentPhase.completed,
          ),
        ),
      _ => item,
    },
];

/// Projeção consolidada usada pelo modo antigo e pela busca local.
List<ToolCall> toolsFromTurnActivity(List<TurnActivity> activity) => [
  for (final item in activity)
    if (item case TurnToolActivity(:final tool)) tool,
];

int _toolTarget(List<TurnActivity> current, ToolCall event) {
  final id = event.id;
  if (id != null && id.isNotEmpty) {
    return current.indexWhere(
      (item) => item is TurnToolActivity && item.tool.id == id,
    );
  }
  if (event.status == ToolStatus.running) return -1;
  return current.indexWhere(
    (item) =>
        item is TurnToolActivity &&
        item.tool.name == event.name &&
        item.tool.status == ToolStatus.running &&
        (item.tool.id == null || item.tool.id!.isEmpty),
  );
}
