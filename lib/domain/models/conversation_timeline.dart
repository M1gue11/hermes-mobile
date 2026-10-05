import 'chat_message.dart';
import 'gateway_scaffolding.dart';
import 'session_message.dart';
import 'tool_call.dart';
import 'tool_preview.dart';
import 'turn_activity.dart';

/// Converte o histórico persistido do gateway na timeline apresentável do chat.
///
/// O gateway persiste **um** turno do agente como **várias** mensagens: a
/// chamada de ferramenta (`role: assistant`, com `tool_calls` e `content`
/// vazio), o resultado (`role: tool`) e, por fim, o texto da resposta. Emitir
/// uma bolha por mensagem produz uma fila de bolhas vazias antes da resposta,
/// que é exatamente o defeito visto ao reabrir uma conversa real.
///
/// Aqui as chamadas e os resultados são acumulados e entregues como a timeline
/// de ferramentas da resposta que os sucede. Nenhuma bolha de assistant é
/// emitida sem algo apresentável.
List<ChatMessage> conversationTimeline(
  List<SessionMessage> persisted, {
  String? model,
}) {
  final timeline = <ChatMessage>[];
  var pendingTools = <ToolCall>[];
  var pendingActivity = <TurnActivity>[];
  final pendingReasoning = StringBuffer();
  SessionMessage? lastPending;
  var activitySerial = 0;

  String nextActivityId(SessionMessage message) =>
      '${message.id}_history_${activitySerial++}';

  void flushPending() {
    if (pendingTools.isEmpty && pendingReasoning.isEmpty) return;
    final anchor = lastPending;
    timeline.add(
      ChatMessage.assistant(
        id: '${anchor?.id ?? 'pendente'}_atividade',
        phase: ChatPhase.done,
        activity: pendingReasoning.toString(),
        tools: _settle(pendingTools),
        activityItems: settleTurnTools(pendingActivity),
        time: _timeFrom(anchor?.timestamp),
        model: model,
      ),
    );
    pendingTools = <ToolCall>[];
    pendingActivity = <TurnActivity>[];
    pendingReasoning.clear();
    lastPending = null;
  }

  for (final message in persisted) {
    switch (message.role) {
      case 'user':
        // Um turno do agente nunca atravessa a fala seguinte do usuário: o que
        // estiver pendente pertence ao turno que acabou. Vale mesmo quando a
        // fala não tem conteúdo: o turno anterior acabou de qualquer forma.
        flushPending();
        // Turno de usuário sem nada dentro não vira bolha. Ver `A19` no
        // backlog: medido no histórico real, o payload tem `content` string de
        // comprimento zero e **todo** o resto nulo, então não há anexo nem
        // parte não textual para anunciar. Uma bolha vazia afirmaria que o
        // usuário falou algo que a tela não consegue mostrar, o que é falso.
        if (message.content.trim().isEmpty) continue;
        timeline.add(
          ChatMessage.user(
            id: message.id,
            text: message.content,
            time: _timeFrom(message.timestamp) ?? '',
            // Andaime do runtime persistido como `user`. Não vira bolha de fala,
            // mas também não some: entrou no contexto do agente. Ver A23.
            scaffolding: isGatewayScaffolding(message.content),
          ),
        );

      case 'assistant':
        final reasoning = _reasoningOf(message);
        if (reasoning.isNotEmpty) {
          if (pendingReasoning.isNotEmpty) pendingReasoning.write('\n');
          pendingReasoning.write(reasoning);
          pendingActivity.add(
            message.reasoningContent?.trim().isNotEmpty == true
                ? TurnActivity.reasoning(
                    id: nextActivityId(message),
                    text: reasoning,
                  )
                : TurnActivity.activity(
                    id: nextActivityId(message),
                    text: reasoning,
                  ),
          );
        }
        for (final tool in _toolCallsOf(message)) {
          pendingActivity = applyTurnToolEvent(
            pendingActivity,
            tool,
            blockId: nextActivityId(message),
          );
        }
        pendingTools = toolsFromTurnActivity(pendingActivity);
        if (message.content.trim().isEmpty) {
          // Turno intermediário: guarda a atividade e não vira bolha.
          lastPending = message;
          continue;
        }
        timeline.add(
          ChatMessage.assistant(
            id: message.id,
            phase: ChatPhase.done,
            activity: pendingReasoning.toString(),
            tools: _settle(pendingTools),
            activityItems: settleTurnTools(pendingActivity),
            text: message.content,
            time: _timeFrom(message.timestamp),
            model: model,
          ),
        );
        pendingTools = <ToolCall>[];
        pendingActivity = <TurnActivity>[];
        pendingReasoning.clear();
        lastPending = null;

      case 'tool':
        final result = _toolResultEvent(pendingTools, message);
        if (result != null) {
          pendingActivity = applyTurnToolEvent(
            pendingActivity,
            result,
            blockId: nextActivityId(message),
          );
          pendingTools = toolsFromTurnActivity(pendingActivity);
        }
        lastPending = message;

      default:
        // `system` e papéis desconhecidos não pertencem à timeline de leitura.
        continue;
    }
  }

  flushPending();
  return timeline;
}

/// O reasoning nativo tem precedência sobre o campo legado.
String _reasoningOf(SessionMessage message) {
  final native = message.reasoningContent?.trim();
  if (native != null && native.isNotEmpty) return native;
  return message.reasoning?.trim() ?? '';
}

/// Lê `tool_calls` no formato OpenAI sem confiar na forma:
/// `[{id, type, function: {name, arguments}}]`.
List<ToolCall> _toolCallsOf(SessionMessage message) {
  final raw = message.toolCalls;
  if (raw is! List) return const [];
  final calls = <ToolCall>[];
  for (final entry in raw) {
    if (entry is! Map) continue;
    final function = entry['function'];
    final name = (function is Map ? function['name'] : entry['name'])
        ?.toString();
    if (name == null || name.isEmpty) continue;
    final arguments =
        (function is Map ? function['arguments'] : entry['arguments'])
            ?.toString() ??
        '';
    calls.add(
      ToolCall(
        id: entry['id']?.toString(),
        name: name,
        // Mesmo resumo que o servidor manda no `preview` ao vivo. Ver A8: antes
        // daqui a mesma chamada lia de dois jeitos conforme a origem.
        arg: toolPreview(name, arguments),
        detail: toolDetail(name, arguments),
      ),
    );
  }
  return calls;
}

/// Casa o resultado (`role: tool`) com a chamada pendente pelo `tool_call_id`.
ToolCall? _toolResultEvent(List<ToolCall> tools, SessionMessage result) {
  final callId = result.toolCallId;
  ToolCall? existing;
  if (callId != null) {
    for (final tool in tools) {
      if (tool.id == callId) {
        existing = tool;
        break;
      }
    }
  }
  final requestedName = result.toolName;
  if (existing == null && requestedName != null) {
    for (final tool in tools) {
      if (tool.name == requestedName && tool.status == ToolStatus.running) {
        existing = tool;
        break;
      }
    }
  }
  final name = requestedName ?? existing?.name;
  if (name == null || name.isEmpty) return null;
  return ToolCall(
    id: callId ?? existing?.id,
    name: name,
    arg: existing?.arg ?? '',
    detail: existing?.detail,
    output: result.content,
    status: ToolStatus.done,
  );
}

/// Histórico é terminal: nada continua "executando" numa conversa reaberta.
List<ToolCall> _settle(List<ToolCall> tools) => [
  for (final tool in tools)
    if (tool.status == ToolStatus.running)
      tool.copyWith(status: ToolStatus.done)
    else
      tool,
];

String? _timeFrom(DateTime? raw) {
  final parsed = raw?.toLocal();
  if (parsed == null) return null;
  return '${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}';
}
