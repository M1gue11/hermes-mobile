import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/active_run_store.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/clarify_request.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/domain/models/model_lock.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_drafts_provider.dart';
import 'package:hermes_mobile/features/settings/settings_provider.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';

import '../support/fake_hermes_repository.dart';
import '../support/fake_gateway_repository.dart';
import '../support/memory_active_run_store.dart';

Future<void> pumpUntil(bool Function() condition, {int max = 8000}) async {
  for (var index = 0; index < max; index++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Condição não atingida a tempo');
}

ProviderContainer makeContainer([
  FakeHermesRepository? repository,
  ActiveRunStore? activeRuns,
  GatewayRepository? gateway,
]) => ProviderContainer(
  overrides: [
    hermesRepositoryProvider.overrideWithValue(
      repository ?? FakeHermesRepository(),
    ),
    runReconciliationDelayProvider.overrideWithValue(Duration.zero),
    activeRunStoreProvider.overrideWithValue(
      activeRuns ?? MemoryActiveRunStore(),
    ),
    if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
  ],
);

void main() {
  test(
    'troca de conversa limpa a anterior antes da hidratação lenta',
    () async {
      final secondHistory = Completer<List<SessionMessage>>();
      final repository = FakeHermesRepository(
        conversationMessagesHandler: (sessionId) {
          if (sessionId == 'session-2') return secondHistory.future;
          return Future.value(const [
            SessionMessage(
              id: 'old-message',
              role: 'assistant',
              content: 'Mensagem da conversa anterior',
            ),
          ]);
        },
      );
      final container = makeContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.openConversation(
        const Conversation(id: 'session-1', title: 'Primeira'),
      );
      expect(container.read(chatControllerProvider).messages, isNotEmpty);

      final opening = controller.openConversation(
        const Conversation(id: 'session-2', title: 'Segunda'),
      );
      final pending = container.read(chatControllerProvider);
      expect(pending.title, 'Segunda');
      expect(pending.messages, isEmpty);
      expect(pending.openingConversation, isTrue);

      secondHistory.complete(const []);
      await opening;
      expect(
        container.read(chatControllerProvider).openingConversation,
        isFalse,
      );
    },
  );

  test('nova sessão envia mensagem, transmite eventos e conclui', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    final sessionId = container.read(chatControllerProvider).sessionId!;
    container
        .read(chatDraftsProvider.notifier)
        .update(sessionId, 'Como faço streaming?');
    expect(await controller.send('Como faço streaming?'), isTrue);
    await pumpUntil(() => !container.read(chatControllerProvider).streaming);

    final state = container.read(chatControllerProvider);
    expect(state.sessionId, isNotNull);
    expect(state.messages, hasLength(2));
    expect(state.title, 'Como faço streaming?');

    final assistant = state.messages.last as AssistantMessage;
    expect(assistant.phase, ChatPhase.done);
    expect(assistant.text, 'Resposta real de teste.');
    expect(assistant.tools, hasLength(1));
    expect(assistant.tools.single.status, ToolStatus.done);
    expect(
      container.read(chatDraftsProvider.notifier).draftFor(sessionId),
      isEmpty,
    );
  });

  test('sessão do Dashboard migra o live chat sem criar run', () async {
    final active = MemoryActiveRunStore();
    final turn = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-1',
    );
    final gateway = FakeGatewayRepository(turns: [turn]);
    final runs = FakeHermesRepository();
    final container = makeContainer(runs, active, gateway);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    final sessionId = container.read(chatControllerProvider).sessionId!;
    container
        .read(chatDraftsProvider.notifier)
        .update(sessionId, 'Use o gateway TUI.');
    expect(await controller.send('Use o gateway TUI.'), isTrue);

    expect(turn.submitted, ['Use o gateway TUI.']);
    expect(runs.historicos, isEmpty, reason: 'nenhuma Runs API foi criada');
    expect(
      active.records['session-2']?.transport,
      ActiveTurnTransport.dashboard,
    );
    expect(
      container.read(activeConversationIdsProvider),
      contains('session-2'),
    );
    expect(
      container.read(chatDraftsProvider.notifier).draftFor(sessionId),
      isEmpty,
    );

    turn.add(const RunEvent.reasoningDelta('Raciocínio nativo.'));
    turn.add(const RunEvent.delta('Resposta'));
    turn.add(
      const RunEvent.clarifyRequest(
        ClarifyRequest(
          requestId: 'clarify-batch',
          questions: [
            ClarifyQuestion(id: 'q0', question: 'Formato?'),
            ClarifyQuestion(id: 'q1', question: 'Detalhe?'),
            ClarifyQuestion(
              id: 'q2',
              question: 'Canais?',
              choices: ['Web', 'Mobile'],
              multiSelect: true,
            ),
            ClarifyQuestion(id: 'q3', question: 'Replay'),
          ],
          answers: {'q3': 'já travada'},
        ),
      ),
    );
    await pumpUntil(
      () =>
          container
              .read(chatControllerProvider)
              .pendingClarification
              ?.requestId ==
          'clarify-batch',
    );
    turn.clarificationRemaining = ['q1', 'q2'];
    expect(
      await controller.respondToClarification('Curto', questionId: 'q0'),
      isNull,
    );
    expect(turn.clarifications.last, (
      requestId: 'clarify-batch',
      questionId: 'q0',
      answer: 'Curto',
    ));
    expect(
      container.read(chatControllerProvider).pendingClarification!.answers,
      containsPair('q0', 'Curto'),
    );
    // Resposta travada pode ser editada enquanto há pergunta pendente: o
    // novo lock substitui a anterior no servidor.
    await controller.respondToClarification('de novo', questionId: 'q0');
    expect(
      turn.clarifications.where((call) => call.questionId == 'q0'),
      hasLength(2),
    );
    expect(
      container.read(chatControllerProvider).pendingClarification!.answers,
      containsPair('q0', 'de novo'),
    );
    // A resposta de replay (q3) também é editável; um skip (`null`) não é.

    turn.clarificationError = const GatewayOperationException('Falha simulada');
    expect(
      await controller.respondToClarification('Livre', questionId: 'q1'),
      'Falha simulada',
    );
    expect(
      container.read(chatControllerProvider).pendingClarification,
      isNotNull,
    );
    expect(
      container.read(chatControllerProvider).clarificationError,
      'Falha simulada',
    );
    turn.clarificationError = null;
    turn.clarificationRemaining = ['q2'];
    await controller.respondToClarification('Livre', questionId: 'q1');
    turn.clarificationRemaining = const [];
    await controller.respondToClarification([
      'Web',
      'Mobile',
    ], questionId: 'q2');
    expect(turn.clarifications.last.answer, ['Web', 'Mobile']);
    expect(container.read(chatControllerProvider).pendingClarification, isNull);

    // Pedido novo: o conjunto de respostas do servidor começa vazio.
    turn.serverAnswers = null;
    turn.add(
      const RunEvent.clarifyRequest(
        ClarifyRequest(
          requestId: 'srq-batch',
          questions: [
            ClarifyQuestion(id: 'q0', question: 'Primeira?'),
            ClarifyQuestion(id: 'q1', question: 'Segunda?'),
            ClarifyQuestion(id: 'q2', question: 'Ignorada?'),
          ],
          answers: {'q0': 'A anterior', 'q2': null},
        ),
      ),
    );
    await pumpUntil(
      () => container.read(chatControllerProvider).pendingClarification != null,
    );
    turn.clarificationRemaining = ['q1'];
    await controller.respondToClarification('não reenviar', questionId: 'q2');
    expect(turn.serverAnswers, isNull);
    await controller.respondToClarification('A atualizada', questionId: 'q0');
    expect(turn.serverAnswers, {'q0': 'A atualizada'});
    expect(
      container.read(chatControllerProvider).pendingClarification!.answers,
      {'q0': 'A atualizada', 'q2': null},
    );
    turn.clarificationRemaining = const [];
    await controller.respondToClarification('B', questionId: 'q1');
    expect(turn.serverAnswers, {'q0': 'A atualizada', 'q1': 'B'});

    turn.clarificationExpired = true;
    turn.add(
      const RunEvent.clarifyRequest(
        ClarifyRequest(
          requestId: 'srq-expired',
          questions: [ClarifyQuestion(id: 'q0', question: 'Expirada?')],
        ),
      ),
    );
    await pumpUntil(
      () => container.read(chatControllerProvider).pendingClarification != null,
    );
    await controller.respondToClarification('A', questionId: 'q0');
    expect(container.read(chatControllerProvider).pendingClarification, isNull);
    expect(
      container.read(chatControllerProvider).clarificationError,
      'Essa pergunta já expirou no gateway.',
    );
    turn.clarificationExpired = false;

    turn.add(
      RunEvent.approvalRequest(
        ApprovalRequest(runId: turn.turnId, command: 'flutter test'),
      ),
    );
    await pumpUntil(
      () => container.read(chatControllerProvider).pendingApproval != null,
    );
    expect(await controller.respondToApproval(ApprovalChoice.once), isNull);
    expect(turn.approvals, [ApprovalChoice.once]);

    turn.add(
      RunEvent.approvalRequest(
        ApprovalRequest(
          runId: turn.turnId,
          requestId: 'srq-approval',
          command: 'echo safe',
        ),
      ),
    );
    await pumpUntil(
      () => container.read(chatControllerProvider).pendingApproval != null,
    );
    turn.add(
      const RunEvent.unknown('request.cancel', {
        'id': 'srq-other',
        'method': 'approval',
        'reason': 'timeout',
      }),
    );
    await Future<void>.delayed(Duration.zero);
    expect(container.read(chatControllerProvider).pendingApproval, isNotNull);
    turn.add(
      const RunEvent.unknown('request.cancel', {
        'id': 'srq-approval',
        'method': 'approval',
        'reason': 'timeout',
      }),
    );
    await pumpUntil(
      () => container.read(chatControllerProvider).pendingApproval == null,
    );

    turn.add(const RunEvent.completed(output: 'Resposta final.'));
    await pumpUntil(() => active.records['session-2'] == null);
    expect(
      container.read(activeConversationIdsProvider),
      isNot(contains('session-2')),
    );

    final state = container.read(chatControllerProvider);
    final assistant = state.messages.last as AssistantMessage;
    expect(assistant.phase, ChatPhase.done);
    expect(assistant.reasoning, 'Raciocínio nativo.');
    expect(assistant.activityItems.single, isA<TurnReasoning>());
    expect(assistant.text, 'Resposta final.');
  });

  test('reconnect do Dashboard retoma histórico sem reenviar prompt', () async {
    final first = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-1',
    );
    final second = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-2',
      initialHistory: const [
        SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
        SessionMessage(id: 'a1', role: 'assistant', content: 'Parcial'),
      ],
    );
    final gateway = FakeGatewayRepository(turns: [first, second]);
    final active = MemoryActiveRunStore();
    final container = makeContainer(FakeHermesRepository(), active, gateway);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    await controller.send('Pergunta');
    expect(first.submitted, ['Pergunta']);

    first.addError(const GatewayOperationException('socket caiu'));
    await pumpUntil(() => gateway.openedSessionIds.length == 2);
    expect(second.submitted, isEmpty, reason: 'prompt nunca é repetido');

    second.add(const RunEvent.completed(output: 'Resposta recuperada.'));
    await pumpUntil(() => active.records['session-2'] == null);
    final assistant =
        container.read(chatControllerProvider).messages.last
            as AssistantMessage;
    expect(assistant.phase, ChatPhase.done);
    expect(assistant.text, 'Resposta recuperada.');
  });

  test('instruções explícitas preservam fallback Runs', () async {
    final turn = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-1',
    );
    final gateway = FakeGatewayRepository(turns: [turn]);
    final runs = FakeHermesRepository();
    final container = makeContainer(runs, MemoryActiveRunStore(), gateway);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    controller.setInstructions('Responda sempre em tópicos.');
    await controller.send('Pergunta');
    await pumpUntil(() => !container.read(chatControllerProvider).streaming);

    expect(gateway.openedSessionIds, isEmpty);
    expect(turn.submitted, isEmpty);
    expect(runs.historicos, hasLength(1));
  });

  test('reabre turno Dashboard concluído usando session.history', () async {
    final active = MemoryActiveRunStore();
    active.records['session-1'] = ActiveRunRecord(
      sessionId: 'session-1',
      runId: 'gateway:live-antiga',
      assistantMessageId: 'assistant-retomado',
      startedAt: DateTime.utc(2026, 8, 10, 10),
      transport: ActiveTurnTransport.dashboard,
    );
    final turn = FakeGatewayLiveTurn(
      storedSessionId: 'session-1',
      liveSessionId: 'live-nova',
      running: false,
      initialHistory: const [
        SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
        SessionMessage(
          id: 'a1',
          role: 'assistant',
          content: 'Concluída enquanto o app estava fechado.',
        ),
      ],
    );
    final gateway = FakeGatewayRepository(turns: [turn]);
    final container = makeContainer(
      FakeHermesRepository(
        messages: {
          'session-1': const [
            SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
          ],
        },
      ),
      active,
      gateway,
    );
    addTearDown(container.dispose);

    await container
        .read(chatControllerProvider.notifier)
        .openConversation(
          const Conversation(id: 'session-1', title: 'Retomada'),
        );

    expect(turn.submitted, isEmpty);
    expect(active.records['session-1'], isNull);
    final state = container.read(chatControllerProvider);
    expect(state.streaming, isFalse);
    expect(
      (state.messages.last as AssistantMessage).text,
      'Concluída enquanto o app estava fechado.',
    );
  });

  test(
    'cold start não troca conversa completa pelo recorte do turno ativo',
    () async {
      final active = MemoryActiveRunStore();
      active.records['session-1'] = ActiveRunRecord(
        sessionId: 'session-1',
        runId: 'gateway:live-antiga',
        assistantMessageId: 'assistant-retomado',
        startedAt: DateTime.utc(2026, 8, 15, 9, 10),
        transport: ActiveTurnTransport.dashboard,
      );
      final turn = FakeGatewayLiveTurn(
        storedSessionId: 'session-1',
        liveSessionId: 'live-nova',
        initialHistory: const [
          // O socket live pode devolver apenas o turno que continua rodando.
          SessionMessage(id: 'u2', role: 'user', content: 'Pergunta atual'),
          SessionMessage(
            id: 'a2',
            role: 'assistant',
            content: 'Resposta atual um pouco mais completa.',
          ),
        ],
      );
      final gateway = FakeGatewayRepository(turns: [turn]);
      final container = makeContainer(
        FakeHermesRepository(
          messages: {
            'session-1': const [
              SessionMessage(
                id: 'u1',
                role: 'user',
                content: 'Pergunta antiga',
              ),
              SessionMessage(
                id: 'a1',
                role: 'assistant',
                content: 'Resposta antiga que não pode sumir.',
              ),
              SessionMessage(id: 'u2', role: 'user', content: 'Pergunta atual'),
              SessionMessage(
                id: 'a2',
                role: 'assistant',
                content: 'Resposta atual parcial.',
              ),
            ],
          },
        ),
        active,
        gateway,
      );
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Retomada'),
          );

      final messages = container.read(chatControllerProvider).messages;
      expect(messages, hasLength(4));
      expect(
        (messages[1] as AssistantMessage).text,
        'Resposta antiga que não pode sumir.',
      );
      expect(messages.last.id, 'assistant-retomado');
      expect(
        (messages.last as AssistantMessage).text,
        'Resposta atual um pouco mais completa.',
      );
    },
  );

  test(
    'cold start acrescenta recorte novo quando HTTP ainda está atrasado',
    () async {
      final active = MemoryActiveRunStore();
      active.records['session-1'] = ActiveRunRecord(
        sessionId: 'session-1',
        runId: 'gateway:live-antiga',
        assistantMessageId: 'assistant-retomado',
        startedAt: DateTime.utc(2026, 8, 15, 9, 10),
        transport: ActiveTurnTransport.dashboard,
      );
      final gateway = FakeGatewayRepository(
        turns: [
          FakeGatewayLiveTurn(
            storedSessionId: 'session-1',
            liveSessionId: 'live-nova',
            initialHistory: const [
              SessionMessage(id: 'u2', role: 'user', content: 'Pergunta nova'),
              SessionMessage(
                id: 'a2',
                role: 'assistant',
                content: 'Respondendo',
              ),
            ],
          ),
        ],
      );
      final container = makeContainer(
        FakeHermesRepository(
          messages: {
            'session-1': const [
              SessionMessage(
                id: 'u1',
                role: 'user',
                content: 'Pergunta antiga',
              ),
              SessionMessage(
                id: 'a1',
                role: 'assistant',
                content: 'Resposta antiga',
              ),
            ],
          },
        ),
        active,
        gateway,
      );
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Retomada'),
          );

      final messages = container.read(chatControllerProvider).messages;
      expect(messages, hasLength(4));
      expect((messages[1] as AssistantMessage).text, 'Resposta antiga');
      expect((messages.last as AssistantMessage).text, 'Respondendo');
    },
  );

  test(
    'cold start reidrata histórico concluído do Dashboard sem run ativa',
    () async {
      final gateway = FakeGatewayRepository(
        histories: {
          'session-1': const [
            SessionMessage(id: 'u1', role: 'user', content: 'Oi'),
            SessionMessage(
              id: 'a1',
              role: 'assistant',
              content: 'Histórico recuperado do TUI.',
            ),
          ],
        },
      );
      final container = makeContainer(
        FakeHermesRepository(messages: const {'session-1': []}),
        MemoryActiveRunStore(),
        gateway,
      );
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Persistida'),
          );

      final state = container.read(chatControllerProvider);
      expect(state.openingConversation, isFalse);
      expect(state.messages, hasLength(2));
      expect(
        (state.messages.last as AssistantMessage).text,
        'Histórico recuperado do TUI.',
      );
      expect(gateway.historySessionIds, ['session-1']);
      expect(
        gateway.openedSessionIds,
        isEmpty,
        reason: 'hidratar histórico não deve adotar uma sessão live',
      );
    },
  );

  test('não envia string vazia', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    await controller.send('   ');
    expect(container.read(chatControllerProvider).messages, isEmpty);
  });

  test('falha antes da Runs API aceitar preserva o rascunho', () async {
    final repository = FakeHermesRepository();
    final container = makeContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    final sessionId = container.read(chatControllerProvider).sessionId!;
    const text = 'Não perder se a rede cair.';
    container.read(chatDraftsProvider.notifier).update(sessionId, text);
    repository.falhaAoCriarRun = StateError('offline');

    expect(await controller.send(text), isFalse);
    expect(
      container.read(chatDraftsProvider.notifier).draftFor(sessionId),
      text,
    );
  });

  test(
    'falha no prompt.submit preserva o rascunho sem cair para Runs',
    () async {
      final turn = FakeGatewayLiveTurn(
        storedSessionId: 'session-2',
        liveSessionId: 'live-1',
        submitError: const GatewayOperationException('socket caiu'),
      );
      final gateway = FakeGatewayRepository(turns: [turn]);
      final runs = FakeHermesRepository();
      final container = makeContainer(runs, MemoryActiveRunStore(), gateway);
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      final sessionId = container.read(chatControllerProvider).sessionId!;
      const text = 'Tentar novamente depois.';
      container.read(chatDraftsProvider.notifier).update(sessionId, text);

      expect(await controller.send(text), isFalse);
      expect(turn.submitted, isEmpty);
      expect(runs.historicos, isEmpty);
      expect(
        container.read(chatDraftsProvider.notifier).draftFor(sessionId),
        text,
      );
    },
  );

  test(
    'conclusão da run encerra qualquer ferramenta sem evento terminal',
    () async {
      final container = makeContainer(
        FakeHermesRepository(emitsToolCompletion: false),
      );
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Faça uma leitura.');
      await pumpUntil(() => !container.read(chatControllerProvider).streaming);

      final assistant =
          container.read(chatControllerProvider).messages.last
              as AssistantMessage;
      expect(assistant.phase, ChatPhase.done);
      expect(assistant.tools.single.status, ToolStatus.done);
    },
  );

  test(
    'fim do stream consulta novamente snapshot ativo até obter saída final',
    () async {
      final stream = ControlledRunStream();
      final container = makeContainer(
        FakeHermesRepository(
          controlledStreams: [stream],
          runSnapshots: const [
            Run(runId: 'ignored', status: RunStatus.running),
            Run(runId: 'ignored', status: RunStatus.running),
            Run(runId: 'ignored', status: RunStatus.running),
            Run(runId: 'ignored', status: RunStatus.running),
            Run(
              runId: 'ignored',
              status: RunStatus.completed,
              output: 'Saída autoritativa.',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Continue após a queda.');
      await pumpUntil(() => stream.hasListener);
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(
            name: 'read_file',
            arg: 'pendente.md',
            status: ToolStatus.running,
          ),
        ),
      );
      stream.close();
      await pumpUntil(() => !container.read(chatControllerProvider).streaming);

      final assistant =
          container.read(chatControllerProvider).messages.last
              as AssistantMessage;
      expect(assistant.phase, ChatPhase.done);
      expect(assistant.text, 'Saída autoritativa.');
      expect(assistant.tools.single.status, ToolStatus.done);
      expect(container.read(chatControllerProvider).streaming, isFalse);
    },
  );

  test(
    'erro depois de abrir o SSE reconcilia sem virar resposta inesperada',
    () async {
      final stream = ControlledRunStream();
      final container = makeContainer(
        FakeHermesRepository(
          controlledStreams: [stream],
          runSnapshots: const [
            Run(runId: 'ignored', status: RunStatus.running),
            Run(
              runId: 'ignored',
              status: RunStatus.completed,
              output: 'Resposta recuperada.',
            ),
          ],
        ),
      );
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Continue apesar da rede.');
      await pumpUntil(() => stream.hasListener);
      stream.add(const RunEvent.delta('Parcial.'));
      stream.addError(StateError('socket caiu'));
      await pumpUntil(() => !container.read(chatControllerProvider).streaming);

      final assistant =
          container.read(chatControllerProvider).messages.last
              as AssistantMessage;
      expect(assistant.phase, ChatPhase.done);
      expect(assistant.text, 'Resposta recuperada.');
      expect(assistant.error, isNull);
    },
  );

  test('reabre stream de run ativa sem reenviar o prompt', () async {
    final stream = ControlledRunStream();
    final runs = MemoryActiveRunStore();
    runs.records['session-1'] = ActiveRunRecord(
      sessionId: 'session-1',
      runId: 'run-1',
      assistantMessageId: 'assistant-retomado',
      startedAt: DateTime.utc(2026, 8, 9, 9, 30),
      model: 'hermes-agent',
    );
    final repository = FakeHermesRepository(
      messages: {
        'session-1': const [
          SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
        ],
      },
      controlledStreams: [stream],
      runSnapshots: const [Run(runId: 'ignored', status: RunStatus.running)],
    );
    final container = makeContainer(repository, runs);
    addTearDown(container.dispose);

    await container
        .read(chatControllerProvider.notifier)
        .openConversation(
          const Conversation(id: 'session-1', title: 'Retomada'),
        );

    await pumpUntil(() => stream.hasListener);
    var state = container.read(chatControllerProvider);
    expect(state.streaming, isTrue);
    expect(state.runId, 'run-1');
    expect(
      (state.messages.last as AssistantMessage).phase,
      ChatPhase.reasoning,
    );
    expect(
      (state.messages.last as AssistantMessage).model,
      'gpt-5.6-terra',
      reason: 'cache antigo não pode recolocar o alias na bolha retomada',
    );
    expect(repository.historicos, isEmpty, reason: 'o prompt não é reenviado');

    stream.add(const RunEvent.delta('Voltamos.'));
    stream.add(const RunEvent.completed(output: 'Resposta completa.'));
    await pumpUntil(() => runs.records['session-1'] == null);

    state = container.read(chatControllerProvider);
    expect(state.streaming, isFalse);
    expect(
      (state.messages.last as AssistantMessage).text,
      'Resposta completa.',
    );
  });

  test('ocultar e retomar uma run mantém uma única assinatura ativa', () async {
    final stream = ControlledRunStream();
    final repository = FakeHermesRepository(
      controlledStreams: [stream],
      runSnapshots: const [Run(runId: 'ignored', status: RunStatus.running)],
    );
    final container = makeContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    await controller.send('Continue em segundo plano.');
    await pumpUntil(() => stream.listenCount == 1);

    await controller.setLiveUpdatesVisible(false);
    expect(stream.cancelCount, 1);
    final beforeLateEvent = container.read(chatControllerProvider).messages;
    stream.add(const RunEvent.delta('Evento tardio ignorado.'));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(chatControllerProvider).messages, beforeLateEvent);

    await controller.setLiveUpdatesVisible(true);
    await pumpUntil(() => stream.listenCount == 2);
    await controller.setLiveUpdatesVisible(true);
    expect(stream.listenCount, 2);
    expect(
      repository.historicos,
      hasLength(1),
      reason: 'o prompt não é reenviado',
    );
  });

  test(
    'retomada aplica conclusão ocorrida fora de foco sem duplicar',
    () async {
      final stream = ControlledRunStream();
      const output = 'Concluída enquanto a conversa estava oculta.';
      final runs = MemoryActiveRunStore();
      final repository = FakeHermesRepository(
        answer: output,
        controlledStreams: [stream],
        runSnapshots: const [
          Run(runId: 'ignored', status: RunStatus.completed, output: output),
        ],
      );
      final container = makeContainer(repository, runs);
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Finalize sem a tela aberta.');
      await pumpUntil(() => stream.listenCount == 1);
      await controller.setLiveUpdatesVisible(false);
      await controller.setLiveUpdatesVisible(true);
      await pumpUntil(() => !container.read(chatControllerProvider).streaming);

      final assistants = container
          .read(chatControllerProvider)
          .messages
          .whereType<AssistantMessage>()
          .where((message) => message.text == output);
      expect(assistants, hasLength(1));
      expect(stream.listenCount, 1, reason: 'run terminal não reconecta o SSE');
      expect(runs.records.values.whereType<ActiveRunRecord>(), isEmpty);
      expect(
        repository.historicos,
        hasLength(1),
        reason: 'o prompt não é reenviado',
      );
    },
  );

  test('retomada do Dashboard abre novo socket sem reenviar prompt', () async {
    final first = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-1',
    );
    final second = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-2',
      initialHistory: const [
        SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
        SessionMessage(id: 'a1', role: 'assistant', content: 'Parcial'),
      ],
    );
    final gateway = FakeGatewayRepository(turns: [first, second]);
    final repository = FakeHermesRepository(
      conversations: const [Conversation(id: 'session-2', title: 'Dashboard')],
      messages: {'session-2': []},
    );
    final container = makeContainer(
      repository,
      MemoryActiveRunStore(),
      gateway,
    );
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.openConversation(
      const Conversation(id: 'session-2', title: 'Dashboard'),
    );
    await controller.send('Pergunta');
    expect(first.submitted, ['Pergunta']);

    await controller.setLiveUpdatesVisible(false);
    expect(first.closed, isTrue);
    await controller.setLiveUpdatesVisible(true);
    expect(gateway.openedSessionIds, ['session-2', 'session-2']);
    expect(second.submitted, isEmpty);
    await controller.setLiveUpdatesVisible(true);
    expect(gateway.openedSessionIds, hasLength(2));
  });

  // A58. O turno em curso não está no histórico do gateway: ele só é
  // persistido ao terminar. Substituir a lista inteira pelo histórico apagava
  // o parcial que estava na tela, e era isso que fazia sair e voltar perder a
  // resposta em andamento.
  test('retomada preserva o parcial que o histórico ainda não tem', () async {
    final first = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-1',
    );
    final second = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-2',
      // O gateway ainda não persistiu nada da resposta: só a pergunta.
      initialHistory: const [
        SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
      ],
    );
    final gateway = FakeGatewayRepository(turns: [first, second]);
    final container = makeContainer(
      FakeHermesRepository(
        conversations: const [Conversation(id: 'session-2', title: 'Live')],
        messages: {'session-2': []},
      ),
      MemoryActiveRunStore(),
      gateway,
    );
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.openConversation(
      const Conversation(id: 'session-2', title: 'Live'),
    );
    await controller.send('Pergunta');
    first.add(const RunEvent.delta('Metade da resposta.'));

    await controller.setLiveUpdatesVisible(false);
    await controller.setLiveUpdatesVisible(true);

    final messages = container.read(chatControllerProvider).messages;
    expect(messages, hasLength(2), reason: 'nada de bolha duplicada');
    expect((messages.last as AssistantMessage).text, 'Metade da resposta.');
  });

  // Mesmo defeito no fallback Runs, que é o caminho mais comum hoje: ao voltar
  // para a tela a bolha era recriada vazia e o parcial sumia.
  //
  // O histórico devolve **só a pergunta**, que é o estado real do servidor no
  // meio de um turno: a resposta só é persistida ao terminar.
  test('retomada pela Runs também preserva o parcial', () async {
    final stream = ControlledRunStream();
    final repository = FakeHermesRepository(
      controlledStreams: [stream],
      runSnapshots: const [Run(runId: 'ignored', status: RunStatus.running)],
      conversationMessagesHandler: (_) async => const [
        SessionMessage(id: 'u1', role: 'user', content: 'Pergunta longa.'),
      ],
    );
    final container = makeContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    await controller.send('Pergunta longa.');
    await pumpUntil(() => stream.hasListener);
    stream.add(const RunEvent.delta('Metade da resposta.'));

    await controller.setLiveUpdatesVisible(false);
    await controller.setLiveUpdatesVisible(true);
    await pumpUntil(() => container.read(chatControllerProvider).streaming);

    final messages = container.read(chatControllerProvider).messages;
    expect((messages.last as AssistantMessage).text, 'Metade da resposta.');
  });

  test('retomada adota o parcial persistido sem criar bolha nova', () async {
    final first = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-1',
    );
    final second = FakeGatewayLiveTurn(
      storedSessionId: 'session-2',
      liveSessionId: 'live-2',
      // Aqui o gateway já gravou parte da resposta, e ela é mais completa que
      // a local: fica a do servidor, e continua sendo uma bolha só.
      initialHistory: const [
        SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
        SessionMessage(
          id: 'a1',
          role: 'assistant',
          content: 'Metade da resposta, e mais um tanto.',
        ),
      ],
    );
    final gateway = FakeGatewayRepository(turns: [first, second]);
    final container = makeContainer(
      FakeHermesRepository(
        conversations: const [Conversation(id: 'session-2', title: 'Live')],
        messages: {'session-2': []},
      ),
      MemoryActiveRunStore(),
      gateway,
    );
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.openConversation(
      const Conversation(id: 'session-2', title: 'Live'),
    );
    await controller.send('Pergunta');
    first.add(const RunEvent.delta('Metade.'));

    await controller.setLiveUpdatesVisible(false);
    await controller.setLiveUpdatesVisible(true);

    final messages = container.read(chatControllerProvider).messages;
    expect(messages, hasLength(2));
    expect(
      (messages.last as AssistantMessage).text,
      'Metade da resposta, e mais um tanto.',
    );
  });

  test(
    'aplica conclusão ocorrida com o app fechado sem duplicar resposta',
    () async {
      final runs = MemoryActiveRunStore();
      runs.records['session-1'] = ActiveRunRecord(
        sessionId: 'session-1',
        runId: 'run-1',
        assistantMessageId: 'assistant-retomado',
        startedAt: DateTime.utc(2026, 8, 9, 9, 30),
      );
      final repository = FakeHermesRepository(
        messages: {
          'session-1': const [
            SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
            SessionMessage(
              id: 'a1',
              role: 'assistant',
              content: 'Concluída enquanto estava fechado.',
            ),
          ],
        },
        runSnapshots: const [
          Run(
            runId: 'ignored',
            status: RunStatus.completed,
            output: 'Concluída enquanto estava fechado.',
          ),
        ],
      );
      final container = makeContainer(repository, runs);
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Retomada'),
          );

      final state = container.read(chatControllerProvider);
      expect(state.messages, hasLength(2));
      expect(
        (state.messages.last as AssistantMessage).text,
        contains('Concluída'),
      );
      expect(runs.records['session-1'], isNull);
    },
  );

  test(
    'run descartada ao reabrir usa histórico e limpa vínculo obsoleto',
    () async {
      final stream = ControlledRunStream();
      final runs = MemoryActiveRunStore();
      runs.records['session-1'] = ActiveRunRecord(
        sessionId: 'session-1',
        runId: 'run-1',
        assistantMessageId: 'assistant-retomado',
        startedAt: DateTime.utc(2026, 8, 10, 9, 30),
      );
      final repository = FakeHermesRepository(
        messages: {
          'session-1': const [
            SessionMessage(id: 'u1', role: 'user', content: 'Pergunta'),
            SessionMessage(
              id: 'a1',
              role: 'assistant',
              content: 'Resposta salva no histórico.',
            ),
          ],
        },
        controlledStreams: [stream],
        runSnapshotResults: const [
          Run(runId: 'ignored', status: RunStatus.running),
          HermesFailure(HermesFailureKind.naoEncontrado, statusCode: 404),
        ],
      );
      final container = makeContainer(repository, runs);
      addTearDown(container.dispose);

      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Retomada'),
          );
      await pumpUntil(() => stream.hasListener);
      stream.addError(
        const HermesFailure(HermesFailureKind.naoEncontrado, statusCode: 404),
      );
      await pumpUntil(() => runs.records['session-1'] == null);

      final state = container.read(chatControllerProvider);
      expect(state.streaming, isFalse);
      expect(state.runId, isNull);
      expect(state.messages, hasLength(2));
      final assistant = state.messages.last as AssistantMessage;
      expect(assistant.phase, ChatPhase.done);
      expect(assistant.text, 'Resposta salva no histórico.');
      expect(assistant.error, isNull);
      expect(
        repository.historicos,
        isEmpty,
        reason: 'o prompt não é reenviado',
      );
    },
  );

  test(
    'turno de usuário vazio do histórico não vira bolha nem volta ao servidor',
    () async {
      // A19: o histórico real tem uma linha `role: user` com `content` vazio. Ela
      // não pode virar bolha, e também não pode ser replicada em
      // `conversation_history`: o `POST /v1/runs` recusa `input` vazio com 400,
      // mas não valida o histórico, então o turno vazio seria persistido de novo.
      final repo = FakeHermesRepository(
        messages: {
          'session-1': [
            const SessionMessage(
              id: 'm1',
              role: 'user',
              content: 'primeira pergunta',
            ),
            const SessionMessage(
              id: 'm2',
              role: 'assistant',
              content: 'primeira resposta',
            ),
            const SessionMessage(id: 'm3', role: 'user', content: ''),
            const SessionMessage(
              id: 'm4',
              role: 'assistant',
              content: 'sessão restaurada',
            ),
          ],
        },
      );
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.openConversation(
        const Conversation(id: 'session-1', title: 'Retomada'),
      );
      expect(
        container
            .read(chatControllerProvider)
            .messages
            .whereType<UserMessage>(),
        hasLength(1),
      );

      await controller.send('e agora?');
      await pumpUntil(() => !container.read(chatControllerProvider).streaming);

      final enviado = repo.historicos.single;
      expect(enviado.where((item) => item['role'] == 'user'), hasLength(1));
      expect(
        enviado.any((item) => (item['content'] as String).trim().isEmpty),
        isFalse,
        reason: 'turno vazio não volta para o servidor',
      );
    },
  );

  test('newChat mantém configurações e cria uma sessão limpa', () async {
    final repository = FakeHermesRepository();
    final container = makeContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    expect(
      await controller.setModel('hermes-agent'),
      contains('não um modelo LLM'),
    );
    controller.setInstructions('Seja objetivo.');
    await controller.newChat();

    final state = container.read(chatControllerProvider);
    expect(state.messages, isEmpty);
    expect(state.title, 'Nova conversa');
    expect(state.modelId, 'gpt-5.6-terra');
    expect(state.modelProvider, 'openai-codex');
    expect(
      repository.criacoes.single,
      const ModelLock(model: 'gpt-5.6-terra', provider: 'openai-codex'),
    );
    expect(state.instructions, 'Seja objetivo.');
    expect(state.sessionId, isNotNull);
  });

  test('configurações reais atualizam o estado', () async {
    final container = makeContainer();
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.setModel('gpt-5.5', provider: 'openai-codex');
    controller.setInstructions('Português.');
    controller.toggleShowActivity();

    final state = container.read(chatControllerProvider);
    expect(state.modelId, 'gpt-5.5');
    expect(state.modelProvider, 'openai-codex');
    expect(state.instructions, 'Português.');
    expect(state.reasoning.showActivity, isFalse);
  });

  test('reabrir sessão legada troca o alias pelo par efetivo', () async {
    final repository = FakeHermesRepository(
      conversations: const [
        Conversation(id: 'legacy', title: 'Legada', model: 'hermes-agent'),
      ],
      messages: const {'legacy': <SessionMessage>[]},
    );
    final container = makeContainer(repository);
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.openConversation(
      const Conversation(id: 'legacy', title: 'Legada', model: 'hermes-agent'),
    );

    final state = container.read(chatControllerProvider);
    expect(state.modelId, 'gpt-5.6-terra');
    expect(state.modelProvider, 'openai-codex');
    expect(
      repository.travas.single,
      const ModelLock(model: 'gpt-5.6-terra', provider: 'openai-codex'),
    );

    await controller.send('Teste o modelo recuperado.');
    await pumpUntil(() => !container.read(chatControllerProvider).streaming);
    expect(repository.modelosRuns.single, 'gpt-5.6-terra');
  });

  test('controller nasce com atividade e instruções restauradas', () {
    final container = ProviderContainer(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        appSettingsInitialProvider.overrideWithValue((
          agentGender: null,
          agentName: null,
          atmosphere: null,
          chronologicalActivity: null,
          spinner: null,
          textSize: null,
          showActivity: false,
          instructions: 'Contexto persistido.',
        )),
      ],
    );
    addTearDown(container.dispose);

    final state = container.read(chatControllerProvider);
    expect(state.reasoning.showActivity, isFalse);
    expect(state.instructions, 'Contexto persistido.');
  });

  test(
    'reabrir omite assistant persistido vazio e preserva resposta útil',
    () async {
      final repository = FakeHermesRepository(
        messages: {
          'session-1': [
            const SessionMessage(
              id: 'u',
              role: 'user',
              content: 'Oi',
              timestamp: null,
            ),
            const SessionMessage(
              id: 'empty',
              role: 'assistant',
              content: '',
              timestamp: null,
            ),
            const SessionMessage(
              id: 'a',
              role: 'assistant',
              content: 'Olá!',
              timestamp: null,
            ),
          ],
        },
      );
      final container = makeContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Persistida'),
          );
      final messages = container.read(chatControllerProvider).messages;
      expect(messages, hasLength(2));
      expect((messages.last as AssistantMessage).text, 'Olá!');
    },
  );

  test(
    'reabrir usa reasoning legado quando reasoningContent persistido está vazio',
    () async {
      final repository = FakeHermesRepository(
        messages: {
          'session-1': [
            const SessionMessage(
              id: 'a',
              role: 'assistant',
              reasoningContent: '',
              reasoning: 'atividade legada',
            ),
          ],
        },
      );
      final container = makeContainer(repository);
      addTearDown(container.dispose);
      await container
          .read(chatControllerProvider.notifier)
          .openConversation(
            const Conversation(id: 'session-1', title: 'Persistida'),
          );
      final message =
          container.read(chatControllerProvider).messages.single
              as AssistantMessage;
      expect(message.text, isEmpty);
      expect(message.activity, 'atividade legada');
      expect(message.reasoning, isEmpty);
    },
  );

  test(
    'chamadas sequenciais da mesma ferramenta preservam a timeline',
    () async {
      final stream = ControlledRunStream();
      final container = makeContainer(
        FakeHermesRepository(controlledStreams: [stream]),
      );
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Leia dois arquivos.');
      await pumpUntil(() => stream.hasListener);
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(
            name: 'read_file',
            arg: 'primeiro.md',
            status: ToolStatus.running,
          ),
        ),
      );
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(
            name: 'read_file',
            arg: 'primeiro.md',
            status: ToolStatus.done,
          ),
        ),
      );
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(
            name: 'read_file',
            arg: 'segundo.md',
            status: ToolStatus.running,
          ),
        ),
      );
      stream.add(
        const RunEvent.toolProgress(
          ToolCall(
            name: 'read_file',
            arg: 'segundo.md',
            status: ToolStatus.done,
          ),
        ),
      );
      stream.add(const RunEvent.completed(output: 'Pronto.'));

      final assistant =
          container.read(chatControllerProvider).messages.last
              as AssistantMessage;
      expect(assistant.tools, hasLength(2));
      expect(assistant.tools.map((tool) => tool.arg), [
        'primeiro.md',
        'segundo.md',
      ]);
      expect(assistant.tools.map((tool) => tool.status), [
        ToolStatus.done,
        ToolStatus.done,
      ]);
    },
  );

  test(
    'callbacks tardios da sessão anterior não alteram a conversa nova',
    () async {
      final oldStream = ControlledRunStream();
      final container = makeContainer(
        FakeHermesRepository(controlledStreams: [oldStream]),
      );
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Conversa antiga.');
      await pumpUntil(() => oldStream.hasListener);
      await controller.newChat();
      final newSessionId = container.read(chatControllerProvider).sessionId;

      oldStream.add(const RunEvent.delta('texto atrasado'));
      oldStream.add(const RunEvent.completed(output: 'fim atrasado'));
      oldStream.close();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(chatControllerProvider);
      expect(state.sessionId, newSessionId);
      expect(state.streaming, isFalse);
      expect(state.messages, isEmpty);
    },
  );

  test(
    'prévia de atividade não é misturada ao texto final nem ao reasoning',
    () async {
      final stream = ControlledRunStream();
      final container = makeContainer(
        FakeHermesRepository(controlledStreams: [stream]),
      );
      addTearDown(container.dispose);
      final controller = container.read(chatControllerProvider.notifier);

      await controller.newChat();
      await controller.send('Mostre a prévia.');
      await pumpUntil(() => stream.hasListener);
      stream.add(const RunEvent.activityPreview('buscando contexto'));
      stream.add(const RunEvent.delta('Resposta parcial.'));
      stream.add(const RunEvent.completed(output: 'Resposta final.'));

      final assistant =
          container.read(chatControllerProvider).messages.last
              as AssistantMessage;
      expect(assistant.activity, 'buscando contexto');
      expect(assistant.text, 'Resposta final.');
      expect(assistant.reasoning, isEmpty);
    },
  );

  test('atividade e ferramenta mantêm a ordem de chegada', () async {
    final stream = ControlledRunStream();
    final container = makeContainer(
      FakeHermesRepository(controlledStreams: [stream]),
    );
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    await controller.send('Faça em etapas.');
    await pumpUntil(() => stream.hasListener);
    stream.add(const RunEvent.activityPreview('Vou abrir o arquivo.'));
    stream.add(
      const RunEvent.toolProgress(ToolCall(name: 'read_file', arg: 'plano.md')),
    );
    stream.add(const RunEvent.activityPreview('Agora posso responder.'));
    stream.add(
      const RunEvent.toolProgress(
        ToolCall(name: 'read_file', duration: '0.2', status: ToolStatus.done),
      ),
    );

    final assistant =
        container.read(chatControllerProvider).messages.last
            as AssistantMessage;
    expect(assistant.activityItems, hasLength(3));
    expect(assistant.activityItems[0], isA<TurnActivityPreview>());
    expect(assistant.activityItems[1], isA<TurnToolActivity>());
    expect(assistant.activityItems[2], isA<TurnActivityPreview>());
    final tool = (assistant.activityItems[1] as TurnToolActivity).tool;
    expect(tool.arg, 'plano.md');
    expect(tool.status, ToolStatus.done);
  });

  // A59. Medido em turno real: quatro `thinking.delta` seguidos deixavam
  // quatro kaomojis permanentes na timeline ao vivo que a conversa reaberta
  // não tinha. Os kaomojis continuam sendo mostrados; o que muda é onde.
  test('o kaomoji vive fora do histórico do turno', () async {
    final stream = ControlledRunStream();
    final container = makeContainer(
      FakeHermesRepository(controlledStreams: [stream]),
    );
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.newChat();
    await controller.send('Pense um pouco.');
    await pumpUntil(() => stream.hasListener);

    AssistantMessage atual() =>
        container.read(chatControllerProvider).messages.last
            as AssistantMessage;

    stream.add(const RunEvent.thinkingState('(´･_･`) reasoning...'));
    expect(atual().thinking, '(´･_･`) reasoning...');

    // Substitui, não empilha.
    stream.add(const RunEvent.thinkingState('٩(๑❛ᴗ❛๑)۶ reflecting...'));
    expect(atual().thinking, '٩(๑❛ᴗ❛๑)۶ reflecting...');
    expect(atual().activityItems, isEmpty);

    // Texto vazio é o sinal de limpeza do gateway, não lixo a descartar.
    stream.add(const RunEvent.thinkingState(''));
    expect(atual().thinking, isEmpty);

    // E o fim do turno não deixa estado preso na tela.
    stream.add(const RunEvent.thinkingState('(・_・;) working...'));
    stream.add(const RunEvent.completed(output: 'Pronto.'));
    expect(atual().thinking, isEmpty);
    expect(atual().activityItems, isEmpty);
  });
}
