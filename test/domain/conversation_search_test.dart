import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation_search.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';

void main() {
  const messages = <ChatMessage>[
    UserMessage(
      id: 'u1',
      text: 'Onde está o relatório da Âncora?',
      time: '09:30',
    ),
    AssistantMessage(
      id: 'a1',
      phase: ChatPhase.done,
      activity: 'Consultando os arquivos',
      tools: [
        ToolCall(
          name: 'search_files',
          arg: 'relatorio final',
          output: 'duas ocorrências encontradas',
        ),
      ],
      text: 'Encontrei o **documento correto**.',
    ),
    UserMessage(id: 'u2', text: 'Outro assunto', time: '09:31'),
  ];

  test('vazio não produz resultado', () {
    expect(conversationSearchMatches(messages, '   '), isEmpty);
  });

  test('ignora caixa, acento e quebra de linha', () {
    expect(conversationSearchMatches(messages, 'ancora'), [0]);
    expect(conversationSearchMatches(messages, 'DOCUMENTO correto'), [1]);
  });

  test('atividade e ferramenta também são pesquisáveis', () {
    expect(conversationSearchMatches(messages, 'consultando'), [1]);
    expect(conversationSearchMatches(messages, 'relatorio final'), [1]);
    expect(conversationSearchMatches(messages, 'duas ocorrencias'), [1]);
  });

  test('cada mensagem aparece uma vez mesmo com mais de uma ocorrência', () {
    const repetida = <ChatMessage>[
      UserMessage(id: 'u', text: 'Hermes, fale do Hermes', time: '10:00'),
    ];
    expect(conversationSearchMatches(repetida, 'hermes'), [0]);
  });

  test('anexo pesquisa nome e legenda, mas não conteúdo escondido', () {
    const anexo = <ChatMessage>[
      UserMessage(
        id: 'u',
        time: '10:00',
        text:
            "[The user sent a text document: 'extrato.csv'. saved at: /tmp/extrato.csv]\n\n"
            '[Content of extrato.csv]:\nsegredo-interno\n\n\nConfira este extrato',
      ),
    ];

    expect(conversationSearchMatches(anexo, 'extrato.csv'), [0]);
    expect(conversationSearchMatches(anexo, 'Confira este extrato'), [0]);
    expect(conversationSearchMatches(anexo, 'segredo-interno'), isEmpty);
  });

  test('resumo injetado pesquisa rótulo e fala, não conteúdo oculto', () {
    const compactacao = <ChatMessage>[
      AssistantMessage(
        id: 'a',
        phase: ChatPhase.done,
        text:
            '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
            'Historical Task Snapshot: token-secreto\n'
            '--- END OF CONTEXT SUMMARY ---\n'
            'Resposta visível sobre o relatório.',
      ),
    ];

    expect(conversationSearchMatches(compactacao, 'resumo da conversa'), [0]);
    expect(conversationSearchMatches(compactacao, 'resposta visivel'), [0]);
    expect(conversationSearchMatches(compactacao, 'Historical Task'), isEmpty);
    expect(conversationSearchMatches(compactacao, 'token-secreto'), isEmpty);
  });
}
