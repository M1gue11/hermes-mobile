import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation_timeline.dart';
import 'package:hermes_mobile/domain/models/gateway_completion.dart';
import 'package:hermes_mobile/domain/models/gateway_turn_projection.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';

void main() {
  test('detalhes de tools não atravessam IDs ou nomes distintos', () {
    const prior = ToolCall(
      id: 'one',
      name: 'terminal',
      output: 'prior output',
      risk: 'flagged',
    );
    for (final incoming in const [
      ToolCall(id: 'two', name: 'terminal'),
      ToolCall(id: 'one', name: 'read_file'),
      ToolCall(name: 'terminal'),
    ]) {
      final merged = mergeGatewayToolDetails(incoming, prior);
      expect(merged.output, isNull);
      expect(merged.risk, isNull);
    }
  });
  test('IDs vazios não correlacionam tools legadas do mesmo nome', () {
    final merged = mergeGatewayToolDetails(
      const ToolCall(id: '', name: 'terminal'),
      const ToolCall(id: '', name: 'terminal', output: 'other call'),
    );
    expect(merged.output, isNull);
  });
  test(
    'comentário, tool e final mantêm a mesma ordem ao vivo e no histórico',
    () {
      var live =
          const ChatMessage.assistant(id: 'a', text: 'Vou verificar.')
              as AssistantMessage;
      live = sealGatewayInterim(
        live,
        text: 'Vou verificar.',
        alreadyStreamed: true,
        id: 'segment',
      );
      live = live.copyWith(
        activityItems: applyTurnToolEvent(
          live.activityItems,
          const ToolCall(id: 't1', name: 'terminal', status: ToolStatus.done),
          blockId: 'tool',
        ),
      );
      live = settleGatewayResponse(
        live.copyWith(text: 'Pronto'),
        output: 'Pronto',
        reasoningId: 'r',
      );
      final history =
          conversationTimeline(const [
                SessionMessage(id: 'u', role: 'user', content: 'Verifique'),
                SessionMessage(
                  id: 'c',
                  role: 'assistant',
                  content: 'Vou verificar.',
                ),
                SessionMessage(
                  id: 't',
                  role: 'tool',
                  toolName: 'terminal',
                  toolCallId: 't1',
                ),
                SessionMessage(id: 'f', role: 'assistant', content: 'Pronto'),
              ]).last
              as AssistantMessage;
      expect(
        live.activityItems.map((i) => i.runtimeType),
        history.activityItems.map((i) => i.runtimeType),
      );
      expect(
        (live.activityItems.first as TurnCommentary).text,
        'Vou verificar.',
      );
      expect(
        (history.activityItems.first as TurnCommentary).text,
        'Vou verificar.',
      );
      expect(live.text, history.text);
    },
  );

  test(
    'as mesmas palavras em comentário e final são duas ocorrências sem flag de reuse',
    () {
      var reply =
          const ChatMessage.assistant(id: 'a', text: 'OK') as AssistantMessage;
      reply = sealGatewayInterim(
        reply,
        text: 'OK',
        alreadyStreamed: true,
        id: 'c',
      );
      reply = settleGatewayResponse(
        reply,
        output: 'OK',
        completion: const GatewayCompletion(),
        reasoningId: 'r',
      );
      expect((reply.activityItems.single as TurnCommentary).text, 'OK');
      expect(reply.text, 'OK');
    },
  );

  test('final reutilizado depois da tool não acrescenta outra resposta', () {
    var reply =
        const ChatMessage.assistant(id: 'a', text: 'OK') as AssistantMessage;
    reply = sealGatewayInterim(
      reply,
      text: 'OK',
      alreadyStreamed: true,
      id: 'c',
    );
    reply = reply.copyWith(
      activityItems: [
        ...reply.activityItems,
        const TurnActivity.tool(
          id: 't',
          tool: ToolCall(id: 't', name: 'terminal'),
        ),
      ],
    );
    reply = settleGatewayResponse(
      reply,
      output: 'OK',
      completion: const GatewayCompletion(previewed: true, reused: true),
      reasoningId: 'r',
    );
    expect(reply.text, isEmpty);
    expect(reply.activityItems.whereType<TurnCommentary>(), hasLength(1));
    expect(
      (reply.activityItems.last as TurnToolActivity).tool.status,
      ToolStatus.done,
    );
  });

  test(
    'transformação substitui o segmento atual mesmo sem prefixo em comum',
    () {
      var reply =
          const ChatMessage.assistant(id: 'a', text: 'TOKEN')
              as AssistantMessage;
      reply = sealGatewayInterim(
        reply,
        text: 'TOKEN',
        alreadyStreamed: true,
        id: 'c',
      );
      reply = settleGatewayResponse(
        reply,
        output: 'Texto transformado',
        completion: const GatewayCompletion(
          transformed: true,
          assistantRowId: 90,
        ),
        reasoningId: 'r',
      );
      expect(
        (reply.activityItems.single as TurnCommentary).text,
        'Texto transformado',
      );
      expect(reply.text, isEmpty);
      expect(reply.rowId, 90);
    },
  );

  test(
    'reasoning terminal completa provider não streaming e preserva partial recuperável',
    () {
      final reply = settleGatewayResponse(
        const ChatMessage.assistant(id: 'a') as AssistantMessage,
        output: 'Parcial útil',
        completion: const GatewayCompletion(
          partial: true,
          recoverable: true,
          reasoning: 'Análise pública',
        ),
        reasoningId: 'r',
      );
      expect(reply.text, 'Parcial útil');
      expect(reply.reasoning, 'Análise pública');
      expect(reply.activityItems.single, isA<TurnReasoning>());
      expect(reply.recoverable, isTrue);
    },
  );
}
