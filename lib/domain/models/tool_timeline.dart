import 'tool_call.dart';

/// Aplica um evento de ferramenta à timeline de um turno, devolvendo a lista
/// nova. Função pura: é aqui que mora a regra de correlação, para poder ser
/// testada sem `dio`, sem servidor e sem widget.
///
/// ## O que a Runs API manda de verdade
///
/// Medido no código-fonte do Hermes `0.19.0`,
/// `gateway/platforms/api_server.py`, `_make_run_event_callback`:
///
/// ```
/// tool.started    {event, run_id, timestamp, tool, preview}
/// tool.completed  {event, run_id, timestamp, tool, duration, error}
/// ```
///
/// Duas consequências que ditam o desenho desta função:
///
/// 1. **Não vem identificador de chamada.** Nem `tool_call_id`, nem `id`. A
///    correlação tem de ser feita por nome e ordem de chegada. Identificador de
///    verdade só existe no gateway TUI, pelo WebSocket, e é por isso que o
///    caminho por `id` continua aqui: quando a trilha B chegar, ele passa a
///    valer e a heurística deixa de ser usada.
/// 2. **`tool.completed` não repete o `preview`.** O argumento só existe no
///    evento de abertura, então fechar uma linha precisa **preservar** o
///    argumento que já está nela. Perder isso é o que produzia linha com nome,
///    duração e mais nada.
///
/// ## A regra
///
/// - Evento com `id` que já existe na lista: casa por `id`, sempre.
/// - Evento `running` sem `id`: **abre uma linha nova**, nunca reaproveita uma
///   aberta. Reaproveitar era o defeito: três `skill_view` em paralelo emitem
///   três `tool.started`, e casar pelo "último ainda rodando" fazia o segundo e
///   o terceiro sobrescreverem o primeiro em vez de somar. Sobrava uma linha
///   aberta para três chamadas, e os dois `tool.completed` seguintes não
///   achavam par.
/// - Evento terminal sem `id`: fecha a linha **mais antiga** ainda aberta com o
///   mesmo nome (FIFO). Sem identificador, ordem de chegada é o melhor palpite
///   disponível; no pior caso duas chamadas de mesmo nome trocam a duração entre
///   si, o que é bem menos grave que perder o argumento.
/// - Evento terminal que não acha linha aberta: entra como linha própria. É um
///   órfão de verdade, por exemplo quando o app assinou o stream no meio da run.
///   Registrar sem argumento é incompleto, mas apagar seria mentir sobre uma
///   ferramenta que rodou.
List<ToolCall> applyToolEvent(List<ToolCall> current, ToolCall event) {
  final index = _target(current, event);
  if (index < 0) return [...current, event];

  final updated = [...current];
  final existing = updated[index];
  updated[index] = event.copyWith(
    id: event.id ?? existing.id,
    arg: event.arg.isEmpty ? existing.arg : event.arg,
    detail: event.detail ?? existing.detail,
    output: event.output ?? existing.output,
    duration: event.duration ?? existing.duration,
  );
  return updated;
}

int _target(List<ToolCall> current, ToolCall event) {
  final id = event.id;
  if (id != null && id.isNotEmpty) {
    return current.indexWhere((item) => item.id == id);
  }
  // Abertura sem identificador é sempre uma chamada nova.
  if (event.status == ToolStatus.running) return -1;
  return current.indexWhere(
    (item) =>
        item.name == event.name &&
        item.status == ToolStatus.running &&
        (item.id == null || item.id!.isEmpty),
  );
}

/// Encerra as linhas que ficaram abertas quando a run terminou. Sem isto, uma
/// run que fecha sem o `tool.completed` de alguma chamada deixaria um spinner
/// girando para sempre no histórico.
List<ToolCall> settleTools(List<ToolCall> tools, {bool failed = false}) {
  return [
    for (final tool in tools)
      if (tool.status == ToolStatus.running)
        tool.copyWith(status: failed ? ToolStatus.error : ToolStatus.done)
      else
        tool,
  ];
}
