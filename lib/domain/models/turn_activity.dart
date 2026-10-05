import 'package:freezed_annotation/freezed_annotation.dart';

import 'tool_call.dart';

part 'turn_activity.freezed.dart';

/// Um acontecimento apresentável dentro de um turno do Hermes.
///
/// A união mantém a semântica que a fonte realmente oferece: prévia de
/// atividade da Runs API, raciocínio nativo quando persistido e chamada de
/// ferramenta. A ordem da lista é a ordem observada pelo cliente.
@freezed
sealed class TurnActivity with _$TurnActivity {
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
    ),
  );
  return updated;
}

/// Encerra ferramentas que ficaram abertas quando a run terminou.
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
