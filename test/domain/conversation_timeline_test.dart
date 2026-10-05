import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation_timeline.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';

/// Chamada de ferramenta no formato que o gateway persiste (OpenAI).
Map<String, dynamic> toolCall(String id, String name, String arguments) => {
  'id': id,
  'type': 'function',
  'function': {'name': name, 'arguments': arguments},
};

void main() {
  test('turno intermediário de tool call não vira bolha vazia', () {
    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'user', content: 'oi'),
      // O gateway persiste a chamada como assistant sem conteúdo.
      SessionMessage(
        id: 'm2',
        role: 'assistant',
        reasoning: 'preciso ler o arquivo',
        toolCalls: [toolCall('call_1', 'read_file', '{"path":"a.dart"}')],
      ),
      const SessionMessage(
        id: 'm3',
        role: 'tool',
        toolName: 'read_file',
        toolCallId: 'call_1',
        content: 'conteudo',
      ),
      const SessionMessage(
        id: 'm4',
        role: 'assistant',
        content: 'Li o arquivo.',
      ),
    ]);

    expect(timeline, hasLength(2));
    final assistant = timeline.last as AssistantMessage;
    expect(assistant.text, 'Li o arquivo.');
    expect(assistant.activity, 'preciso ler o arquivo');
    expect(assistant.tools.single.name, 'read_file');
    expect(assistant.tools.single.status, ToolStatus.done);
    expect(assistant.activityItems[0], isA<TurnActivityPreview>());
    expect(assistant.activityItems[1], isA<TurnToolActivity>());
    expect(
      (assistant.activityItems[1] as TurnToolActivity).tool.status,
      ToolStatus.done,
    );
  });

  test('resultado casa pelo tool_call_id mesmo fora de ordem', () {
    final timeline = conversationTimeline([
      SessionMessage(
        id: 'm1',
        role: 'assistant',
        toolCalls: [
          toolCall('a', 'grep', '{}'),
          toolCall('b', 'read_file', '{}'),
        ],
      ),
      const SessionMessage(
        id: 'm2',
        role: 'tool',
        toolCallId: 'b',
        toolName: 'read_file',
      ),
      const SessionMessage(id: 'm3', role: 'assistant', content: 'pronto'),
    ]);

    final tools = (timeline.single as AssistantMessage).tools;
    expect(tools.map((t) => t.name), ['grep', 'read_file']);
    // Histórico é terminal: nada fica girando numa conversa reaberta.
    expect(tools.every((t) => t.status == ToolStatus.done), isTrue);
  });

  test('histórico preserva comando seguro e saída para expansão', () {
    final timeline = conversationTimeline([
      SessionMessage(
        id: 'm1',
        role: 'assistant',
        toolCalls: [
          toolCall(
            'call_1',
            'terminal',
            '{"command":"unzip pacote.zip arquivo.md"}',
          ),
        ],
      ),
      const SessionMessage(
        id: 'm2',
        role: 'tool',
        toolName: 'terminal',
        toolCallId: 'call_1',
        content: 'inflating: arquivo.md\nexit 0',
      ),
      const SessionMessage(id: 'm3', role: 'assistant', content: 'Pronto.'),
    ]);

    final tool = (timeline.single as AssistantMessage).tools.single;
    expect(tool.detail, 'unzip pacote.zip arquivo.md');
    expect(tool.output, 'inflating: arquivo.md\nexit 0');
  });

  test('atividade sem resposta final ainda é preservada', () {
    final timeline = conversationTimeline([
      SessionMessage(
        id: 'm1',
        role: 'assistant',
        reasoning: 'chamando',
        toolCalls: [toolCall('call_1', 'shell', '{}')],
      ),
    ]);

    final assistant = timeline.single as AssistantMessage;
    expect(assistant.text, isEmpty);
    expect(assistant.tools.single.name, 'shell');
    expect(assistant.activity, 'chamando');
  });

  test('fala do usuário fecha o turno pendente antes de entrar', () {
    final timeline = conversationTimeline([
      SessionMessage(
        id: 'm1',
        role: 'assistant',
        toolCalls: [toolCall('call_1', 'shell', '{}')],
      ),
      const SessionMessage(id: 'm2', role: 'user', content: 'para'),
    ]);

    expect(timeline, hasLength(2));
    expect(timeline.first, isA<AssistantMessage>());
    expect(timeline.last, isA<UserMessage>());
  });

  test('reasoning nativo tem precedência sobre o campo legado', () {
    final timeline = conversationTimeline([
      const SessionMessage(
        id: 'm1',
        role: 'assistant',
        content: 'ok',
        reasoning: 'legado',
        reasoningContent: 'nativo',
      ),
    ]);

    final assistant = timeline.single as AssistantMessage;
    expect(assistant.activity, 'nativo');
    expect(assistant.activityItems.single, isA<TurnReasoning>());
  });

  test('papel system fica fora da timeline de leitura', () {
    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'system', content: 'prompt'),
      const SessionMessage(id: 'm2', role: 'user', content: 'oi'),
    ]);

    expect(timeline, hasLength(1));
    expect(timeline.single, isA<UserMessage>());
  });

  test('o modelo da sessão é propagado para o cabeçalho da bolha', () {
    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'assistant', content: 'ok'),
    ], model: 'gpt-5.6-terra');

    expect((timeline.single as AssistantMessage).model, 'gpt-5.6-terra');
  });

  test('turno de usuário sem conteúdo não vira bolha vazia', () {
    // A19, medido no histórico real: a linha existe com `content` de
    // comprimento zero e todo o resto nulo. Não há o que mostrar, e a bolha
    // vazia afirmava uma fala que não houve.
    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'user', content: 'oi'),
      const SessionMessage(id: 'm2', role: 'assistant', content: 'olá'),
      const SessionMessage(id: 'm3', role: 'user', content: ''),
      const SessionMessage(
        id: 'm4',
        role: 'assistant',
        content: 'sessão restaurada',
      ),
    ]);

    expect(timeline.whereType<UserMessage>(), hasLength(1));
    expect(timeline, hasLength(3));
    // A resposta que veio depois continua na tela: quem some é a bolha vazia,
    // não o que o Hermes disse.
    expect((timeline.last as AssistantMessage).text, 'sessão restaurada');
  });

  test('turno de usuário só com espaço em branco também não vira bolha', () {
    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'user', content: '   \n  '),
    ]);

    expect(timeline, isEmpty);
  });

  test('turno vazio ainda fecha a atividade pendente do turno anterior', () {
    // O turno do agente acabou de qualquer forma; engolir a fala vazia não
    // pode engolir junto as ferramentas que vieram antes dela.
    final timeline = conversationTimeline([
      SessionMessage(
        id: 'm1',
        role: 'assistant',
        toolCalls: [toolCall('call_1', 'shell', '{}')],
      ),
      const SessionMessage(id: 'm2', role: 'user', content: ''),
      const SessionMessage(id: 'm3', role: 'assistant', content: 'pronto'),
    ]);

    expect(timeline, hasLength(2));
    expect((timeline.first as AssistantMessage).tools.single.name, 'shell');
    expect((timeline.last as AssistantMessage).text, 'pronto');
    expect((timeline.last as AssistantMessage).tools, isEmpty);
  });

  test('conteúdo não textual não é confundido com turno vazio', () {
    // O adapter converte `content` que não é string com `toString()`, então
    // uma mensagem multimodal chega como texto não vazio e **continua**
    // aparecendo. A regra do A19 só descarta o que é de fato vazio.
    final timeline = conversationTimeline([
      const SessionMessage(
        id: 'm1',
        role: 'user',
        content: '[{type: image_url, image_url: {url: …}}]',
      ),
    ]);

    expect(timeline.single, isA<UserMessage>());
  });

  test('tool_calls com forma inesperada não derruba a leitura', () {
    final timeline = conversationTimeline([
      const SessionMessage(
        id: 'm1',
        role: 'assistant',
        content: 'ok',
        toolCalls: 'nao e uma lista',
      ),
    ]);

    expect((timeline.single as AssistantMessage).tools, isEmpty);
  });
}
