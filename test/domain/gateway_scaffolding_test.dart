import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation_timeline.dart';
import 'package:hermes_mobile/domain/models/gateway_scaffolding.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';

/// A23: turno `role: user` que o runtime injetou.
///
/// Os marcadores saíram de `_SYNTHETIC_USER_PREFIXES`
/// (`agent/conversation_compression.py`), `TODO_INJECTION_HEADER`
/// (`tools/todo_tool.py`) e `SUMMARY_PREFIX`/`LEGACY_SUMMARY_PREFIX`
/// (`agent/context_compressor.py`), na versão `0.19.0`.
void main() {
  test('reconhece o andaime que apareceu no aparelho', () {
    expect(
      isGatewayScaffolding(
        '[Your active task list was preserved across context compression]\n'
        '- [>] rules. Salvar as categorizações confirmadas',
      ),
      isTrue,
    );
  });

  test('reconhece as demais injeções que o servidor lista', () {
    const casos = [
      '[System: Your previous response was truncated at the token limit]',
      '[System: The previous response was cut off]',
      '[System: Your previous tool call was dropped]',
      '[IMPORTANT: Background process 42 finished]',
      '[CONTEXT SUMMARY]: conversa anterior',
      '[CONTEXT COMPACTION',
      '[PRIOR CONTEXT',
    ];
    for (final texto in casos) {
      expect(isGatewayScaffolding(texto), isTrue, reason: texto);
    }
  });

  test('reconhece os marcadores comparados por igualdade', () {
    expect(
      isGatewayScaffolding(
        'Continue from the compressed conversation context above. '
        'This marker exists because no human user turn was available.',
      ),
      isTrue,
    );
  });

  test('fala de gente continua sendo fala de gente', () {
    const reais = [
      'Assistente, preciso adicionar compromissos à agenda esta semana',
      'bom dia assistente! tranquilo?',
      // Colchete no começo não basta: tem de ser um marcador conhecido.
      '[nota] lembra de me avisar amanhã',
      'o system: nao respondeu',
      '',
      '   ',
    ];
    for (final texto in reais) {
      expect(isGatewayScaffolding(texto), isFalse, reason: texto);
    }
  });

  test('o rótulo diz o que foi injetado, sem despejar o texto', () {
    expect(
      gatewayScaffoldingLabel(
        '[Your active task list was preserved across context compression]',
      ),
      'lista de tarefas preservada na compactação',
    );
    expect(
      gatewayScaffoldingLabel('[CONTEXT SUMMARY]: x'),
      'resumo da conversa anterior',
    );
    expect(
      gatewayScaffoldingLabel('[System: Your previous tool call was dropped'),
      'aviso de chamada de ferramenta perdida',
    );
  });

  test('separa resumo isolado sem inventar conteúdo visível', () {
    final dash = String.fromCharCode(0x2014);
    final raw =
        '[CONTEXT COMPACTION $dash REFERENCE ONLY]\n'
        'Historical Task Snapshot\n'
        'segredo interno';

    final split = splitGatewayScaffolding(raw)!;

    expect(split.injected, raw);
    expect(split.visible, isEmpty);
  });

  test('separa resposta legítima anexada após o fim do resumo', () {
    final dash = String.fromCharCode(0x2014);
    final raw =
        '[CONTEXT COMPACTION $dash REFERENCE ONLY]\n'
        'Historical Task Snapshot\n'
        '--- END OF CONTEXT SUMMARY ---\n'
        'Resposta legítima do Hermes.';

    final split = splitGatewayScaffolding(raw)!;

    expect(split.injected, contains('Historical Task Snapshot'));
    expect(split.injected, isNot(contains('END OF CONTEXT SUMMARY')));
    expect(split.visible, 'Resposta legítima do Hermes.');
  });

  test('preserva fala anterior dentro do envelope prior context', () {
    const raw =
        '[PRIOR CONTEXT - for reference only; not a new message]\n'
        'Resposta anterior que continua sendo do Hermes.\n'
        '[END OF PRIOR CONTEXT - COMPACTION SUMMARY BELOW]\n'
        '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
        'Historical Task Snapshot\n'
        '--- END OF CONTEXT SUMMARY ---';

    final split = splitGatewayScaffolding(raw)!;

    expect(split.injected, contains('[PRIOR CONTEXT'));
    expect(split.injected, contains('[END OF PRIOR CONTEXT'));
    expect(split.injected, contains('Historical Task Snapshot'));
    expect(split.visible, 'Resposta anterior que continua sendo do Hermes.');
  });

  test('texto comum não é dividido', () {
    expect(splitGatewayScaffolding('Resposta comum.'), isNull);
  });

  test('a timeline marca o turno, e não o descarta', () {
    // Esconder apagaria da leitura algo que entrou no contexto do agente e
    // mudou a resposta seguinte.
    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'user', content: 'oi'),
      const SessionMessage(
        id: 'm2',
        role: 'user',
        content:
            '[Your active task list was preserved across context compression]',
      ),
      const SessionMessage(id: 'm3', role: 'assistant', content: 'segue'),
    ]);

    final usuarios = timeline.whereType<UserMessage>().toList();
    expect(usuarios, hasLength(2));
    expect(usuarios.first.scaffolding, isFalse);
    expect(usuarios.last.scaffolding, isTrue);
  });

  test('a timeline preserva integralmente resumo com papel assistant', () {
    const raw =
        '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
        'Historical Task Snapshot\n'
        '--- END OF CONTEXT SUMMARY ---\n'
        'Resposta real.';

    final timeline = conversationTimeline([
      const SessionMessage(id: 'm1', role: 'assistant', content: raw),
    ]);

    final assistant = timeline.single as AssistantMessage;
    expect(assistant.text, raw);
  });
}
