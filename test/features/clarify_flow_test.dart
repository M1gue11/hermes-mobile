import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/clarify_request.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';
import 'package:hermes_mobile/features/settings/agent_persona.dart';

import '../support/fake_hermes_repository.dart';

const _request = ClarifyRequest(
  requestId: 'clarify-1',
  questions: [
    ClarifyQuestion(
      id: 'q0',
      question: 'Como você prefere receber a resposta?',
      choices: ['Curta', 'Detalhada'],
    ),
  ],
);

const _batch = ClarifyRequest(
  requestId: 'clarify-batch',
  questions: [
    ClarifyQuestion(id: 'q0', question: 'Primeira?', choices: ['A', 'B']),
    ClarifyQuestion(id: 'q1', question: 'Segunda?'),
    ClarifyQuestion(
      id: 'q2',
      question: 'Terceira?',
      choices: ['Um', 'Dois'],
      multiSelect: true,
    ),
    ClarifyQuestion(id: 'q3', question: 'Já respondida?'),
  ],
  answers: {'q3': null},
);

const _serverReplayBatch = ClarifyRequest(
  requestId: 'clarify-server-replay',
  questions: [
    ClarifyQuestion(id: 'q0', question: 'Resposta anterior?'),
    ClarifyQuestion(id: 'q1', question: 'Ainda falta?'),
    ClarifyQuestion(
      id: 'q2',
      question: 'Escolhas anteriores?',
      choices: ['Web', 'Mobile'],
      multiSelect: true,
    ),
    ClarifyQuestion(id: 'q3', question: 'Ignorada?'),
  ],
  answers: {
    'q0': 'Anterior',
    'q2': ['Web'],
    'q3': null,
  },
);

void main() {
  testWidgets('mostra escolhas e só responde depois de um gesto', (
    tester,
  ) async {
    final answers = <Object>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: ClarifyCard(
            request: _request,
            onAnswer: (_, answer) => answers.add(answer),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('clarify-card')), findsOneWidget);
    expect(find.text(_request.questions.single.question), findsOneWidget);
    expect(answers, isEmpty, reason: 'nada é respondido por omissão');

    await tester.tap(find.byKey(const ValueKey('clarify-choice-q0-Curta')));
    expect(answers, ['Curta']);
  });

  testWidgets('aceita texto livre e bloqueia envio duplo enquanto responde', (
    tester,
  ) async {
    final answers = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: ClarifyCard(
            request: _request,
            respondingTo: 'q0',
            onAnswer: (_, answer) => answers.add(answer as String),
          ),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('clarify-choice-q0-Curta')),
      warnIfMissed: false,
    );
    expect(answers, isEmpty);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: ClarifyCard(
            request: _request,
            onAnswer: (_, answer) => answers.add(answer as String),
          ),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('clarify-answer-q0-')),
      '  Em tópicos  ',
    );
    await tester.tap(find.byKey(const ValueKey('clarify-submit-q0-')));
    expect(answers, ['Em tópicos']);
  });

  testWidgets('nome e gênero chegam ao rótulo e à acessibilidade', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: ClarifyCard(
            request: _request,
            persona: AgentPersona(
              name: 'Cláudia',
              gender: AgentGender.feminine,
            ),
            onAnswer: _ignoreAnswer,
          ),
        ),
      ),
    );

    expect(find.text('CLÁUDIA PERGUNTA'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'A Cláudia está te perguntando algo',
      ),
      findsOneWidget,
    );
  });

  testWidgets('texto longo se adapta sem overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SizedBox(
            width: 320,
            child: ClarifyCard(
              request: ClarifyRequest(
                requestId: 'longa',
                questions: [
                  ClarifyQuestion(
                    id: 'q0',
                    question:
                        'Explique com bastante detalhe qual destas alternativas deve ser priorizada, incluindo acentos, emoji 🧭 e uma observação adicional que faça a pergunta quebrar em várias linhas.',
                  ),
                ],
              ),
              onAnswer: _ignoreAnswer,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'batch mostra pendentes, trava replay e envia lista multi-select',
    (tester) async {
      final sent = <({String id, Object answer})>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: ClarifyCard(
              request: _batch,
              onAnswer: (id, answer) => sent.add((id: id, answer: answer)),
            ),
          ),
        ),
      );

      expect(find.text('Primeira?'), findsOneWidget);
      expect(find.text('Segunda?'), findsOneWidget);
      expect(find.text('Terceira?'), findsOneWidget);
      // Uma resposta não nula seria editável; só o skip aparece como concluído.
      expect(find.text('✓ Já respondida?\nPergunta ignorada'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('clarify-choice-q0-A')));
      await tester.enterText(
        find.byKey(const ValueKey('clarify-answer-q1-')),
        'Livre',
      );
      await tester.tap(find.byKey(const ValueKey('clarify-submit-q1-')));
      await tester.tap(find.byKey(const ValueKey('clarify-choice-q2-Um')));
      await tester.tap(find.byKey(const ValueKey('clarify-choice-q2-Dois')));
      await tester.tap(find.byKey(const ValueKey('clarify-submit-q2-')));

      expect(sent, hasLength(3));
      expect(sent[0], (id: 'q0', answer: 'A'));
      expect(sent[1], (id: 'q1', answer: 'Livre'));
      expect(sent[2].id, 'q2');
      expect(sent[2].answer, orderedEquals(['Um', 'Dois']));
    },
  );

  testWidgets('erro mantém texto para retry no mesmo pedido', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: ClarifyCard(request: _request, onAnswer: _ignoreAnswer),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('clarify-answer-q0-')),
      'Não apagar',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: ClarifyCard(
            request: _request,
            error: 'Falha de rede',
            onAnswer: _ignoreAnswer,
          ),
        ),
      ),
    );
    expect(find.text('Falha de rede'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('clarify-answer-q0-')))
          .controller!
          .text,
      'Não apagar',
    );
  });

  testWidgets('server request permite editar replay antes da última resposta', (
    tester,
  ) async {
    final sent = <({String id, Object answer})>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: ClarifyCard(
            request: _serverReplayBatch,
            onAnswer: (id, answer) => sent.add((id: id, answer: answer)),
          ),
        ),
      ),
    );

    final previous = tester.widget<TextField>(
      find.byKey(const ValueKey('clarify-answer-q0-')),
    );
    expect(previous.controller!.text, 'Anterior');
    expect(find.text('✓ Ignorada?\nPergunta ignorada'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('clarify-answer-q0-')),
      'Atualizada',
    );
    await tester.tap(find.byKey(const ValueKey('clarify-submit-q0-')));

    expect(sent, [(id: 'q0', answer: 'Atualizada')]);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('clarify-answer-q2-')))
          .controller!
          .text,
      isEmpty,
      reason:
          'a escolha replayada fica pré-selecionada, não vira texto inválido',
    );
  });

  testWidgets('composer fica bloqueado enquanto o gateway espera resposta', (
    tester,
  ) async {
    const state = ChatState(
      sessionId: 'session-1',
      runId: 'gateway:live-1',
      streaming: true,
      pendingClarification: _request,
      messages: [
        UserMessage(id: 'u1', text: 'Pergunta', time: '10:00'),
        AssistantMessage(id: 'a1', phase: ChatPhase.reasoning, time: '10:00'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWithValue(state),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        ],
        child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('clarify-card')), findsOneWidget);
    final composer = tester.widget<TextField>(find.byType(TextField).last);
    expect(composer.enabled, isFalse);
    expect(find.text('Aguardando sua decisão acima…'), findsOneWidget);
  });

  testWidgets('batch aparece com thread vazia e mantém composer bloqueado', (
    tester,
  ) async {
    const state = ChatState(
      sessionId: 'session-1',
      runId: 'gateway:live-1',
      streaming: true,
      pendingClarification: _batch,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWithValue(state),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        ],
        child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('clarify-card')), findsOneWidget);
    expect(find.text('Primeira?'), findsOneWidget);
    expect(find.text('Terceira?'), findsOneWidget);
    final composer = tester.widget<TextField>(find.byType(TextField).last);
    expect(composer.enabled, isFalse);
  });
}

void _ignoreAnswer(String questionId, Object answer) {}
