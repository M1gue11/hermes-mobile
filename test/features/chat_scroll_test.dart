import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/hermes_route_observer.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import '../support/stub_chat_launch.dart';

/// Thread comprida o bastante para rolar de verdade no viewport de teste.
ChatState threadWith(int turns) => ChatState(
  sessionId: 'sessao-1',
  messages: [
    for (var i = 0; i < turns; i++) ...[
      UserMessage(id: 'u$i', text: 'Pergunta número $i', time: '09:${i % 60}'),
      AssistantMessage(
        id: 'a$i',
        phase: ChatPhase.done,
        text:
            'Resposta número $i, com texto suficiente para ocupar altura '
            'e obrigar a lista a rolar de verdade no teste de widget.',
      ),
    ],
  ],
);

/// Uma única mensagem nova, para o contador ser inequívoco.
ChatState plusOne(ChatState state) => state.copyWith(
  messages: [
    ...state.messages,
    const AssistantMessage(
      id: 'nova',
      phase: ChatPhase.done,
      text: 'Resposta que chegou enquanto o usuário lia mais acima.',
    ),
  ],
);

ChatState withApproval(ChatState state) => state.copyWith(
  streaming: true,
  pendingApproval: const ApprovalRequest(
    runId: 'run-scroll',
    command: 'terminal comando-longo',
    description: 'O Hermes precisa de autorização para continuar.',
    choices: [
      ApprovalChoice.once,
      ApprovalChoice.session,
      ApprovalChoice.always,
      ApprovalChoice.deny,
    ],
  ),
);

ChatState streamingThread(String text) {
  final base = threadWith(12);
  final last = base.messages.last as AssistantMessage;
  return base.copyWith(
    streaming: true,
    messages: [
      ...base.messages.take(base.messages.length - 1),
      last.copyWith(phase: ChatPhase.writing, text: text),
    ],
  );
}

ChatState expandableToolThread() {
  final base = threadWith(11);
  return base.copyWith(
    messages: [
      ...base.messages,
      const UserMessage(
        id: 'tool-user',
        text: 'Mostre o trabalho',
        time: '10:00',
      ),
      const AssistantMessage(
        id: 'tool-answer',
        phase: ChatPhase.done,
        activityItems: [
          TurnActivity.tool(
            id: 'anchor-tool',
            tool: ToolCall(
              name: 'read_file',
              arg: 'lib/main.dart',
              detail: 'lib/main.dart',
              output: 'linha 1\nlinha 2\nlinha 3\nlinha 4\nlinha 5\nlinha 6',
              status: ToolStatus.done,
            ),
          ),
        ],
        text: 'Conteúdo depois da ferramenta.',
      ),
    ],
  );
}

Widget harness(ChatState state) => ProviderScope(
  overrides: [
    chatControllerProvider.overrideWithValue(state),
    hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
  ],
  child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
);

Widget liveHarness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.build(),
    navigatorObservers: [hermesRouteObserver],
    home: const ChatScreen(),
  ),
);

/// O botão está sempre na árvore; o que muda é a opacidade.
double jumpOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.byKey(const ValueKey('jump-to-end')),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

ScrollController controllerOf(WidgetTester tester) =>
    tester.widget<ListView>(find.byType(ListView)).controller!;

void expectAtEnd(ScrollController scroll) {
  expect(
    scroll.position.pixels,
    moreOrLessEquals(scroll.position.maxScrollExtent, epsilon: 1),
  );
}

Finder visibleQuestionAnchor(WidgetTester tester) {
  final viewport = tester.getRect(find.byType(ListView));
  for (var i = 0; i < 12; i++) {
    final candidate = find.text('Pergunta número $i');
    if (candidate.evaluate().length != 1) continue;
    final rect = tester.getRect(candidate);
    if (rect.bottom > viewport.top && rect.top < viewport.bottom) {
      return candidate;
    }
  }
  throw StateError('nenhuma pergunta visível para servir de âncora');
}

void main() {
  testWidgets('o primeiro turno começa no topo da área de conversa', (
    tester,
  ) async {
    final firstTurn = ChatState(
      sessionId: 'sessao-1',
      messages: const [
        UserMessage(id: 'u1', text: 'Oi', time: '09:30'),
        AssistantMessage(
          id: 'a1',
          phase: ChatPhase.done,
          text: 'Como posso ajudar?',
        ),
      ],
    );

    await tester.pumpWidget(harness(firstTurn));
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byKey(const ValueKey('chat-thread')));
    final firstMessage = tester.getRect(find.text('Oi'));
    expect(
      firstMessage.top,
      lessThan(viewport.top + 90),
      reason: 'uma conversa curta deve começar no topo, não no rodapé',
    );
    expect(tester.widget<ListView>(find.byType(ListView)).reverse, isFalse);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('abre no fim cronológico e sem oferecer retorno', (tester) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    final scroll = controllerOf(tester);
    expect(tester.widget<ListView>(find.byType(ListView)).reverse, isFalse);
    expectAtEnd(scroll);
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('subir para reler não é desfeito pela mensagem que chega', (
    tester,
  ) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    // O usuário sobe para reler.
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();

    final scroll = controllerOf(tester);
    final parado = scroll.position.pixels;
    expect(scroll.position.maxScrollExtent - parado, greaterThan(24));
    expect(jumpOpacity(tester), 1);
    final anchor = visibleQuestionAnchor(tester);
    final anchorTop = tester.getTopLeft(anchor).dy;

    // Chega mensagem nova enquanto ele lê mais acima.
    await tester.pumpWidget(harness(plusOne(threadWith(12))));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(anchor).dy,
      moreOrLessEquals(anchorTop, epsilon: 1),
      reason: 'a tinta visível deve permanecer fixa quando conteúdo novo chega',
    );
    expect(
      controllerOf(tester).position.pixels,
      moreOrLessEquals(parado, epsilon: 1),
      reason: 'conteúdo acrescentado no fim não altera o offset de releitura',
    );
    expect(find.text('1 NOVA'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('um gesto curto pausa e voltar ao fim não reata', (tester) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    final gesture = await tester.startGesture(tester.getCenter(list));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final scroll = controllerOf(tester);
    final distanceFromEnd =
        scroll.position.maxScrollExtent - scroll.position.pixels;
    expect(distanceFromEnd, greaterThan(0));
    expect(distanceFromEnd, lessThan(24));
    expect(jumpOpacity(tester), 1);

    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pump();
    expectAtEnd(scroll);
    expect(
      jumpOpacity(tester),
      1,
      reason: 'só uma ação explícita pode reatar o acompanhamento',
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tokens novos preservam a tinta quando a leitura está pausada', (
    tester,
  ) async {
    await tester.pumpWidget(harness(streamingThread('Resposta parcial.')));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    final anchor = visibleQuestionAnchor(tester);
    final anchorTop = tester.getTopLeft(anchor).dy;

    await tester.pumpWidget(
      harness(
        streamingThread(
          'Resposta parcial.\n\n'
          'Novo parágrafo recebido durante o streaming, com altura suficiente '
          'para alterar o extent sem deslocar o trecho que está sendo relido.\n\n'
          'Mais uma linha para reproduzir a chegada contínua de tokens.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(anchor).dy,
      moreOrLessEquals(anchorTop, epsilon: 1),
    );
    expect(jumpOpacity(tester), 1);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('sem gesto, tokens novos continuam presos ao fim', (
    tester,
  ) async {
    await tester.pumpWidget(harness(streamingThread('Resposta parcial.')));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      harness(
        streamingThread(
          'Resposta parcial.\n\nNovo conteúdo chegando no fim da conversa.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectAtEnd(controllerOf(tester));
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tool cresce para baixo e pode ser recolhida sem scroll', (
    tester,
  ) async {
    await tester.pumpWidget(harness(expandableToolThread()));
    await tester.pumpAndSettle();

    final toggle = find.byKey(const ValueKey('turn-tool-toggle-anchor-tool'));
    final below = find.text('Conteúdo depois da ferramenta.');
    final toggleTop = tester.getTopLeft(toggle).dy;
    final belowTop = tester.getTopLeft(below).dy;

    await tester.tap(toggle);
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump();
      expect(
        tester.getTopLeft(toggle).dy,
        moreOrLessEquals(toggleTop, epsilon: 1),
      );
    }
    expect(tester.getTopLeft(below).dy, greaterThan(belowTop));
    expect(jumpOpacity(tester), 1);

    // O mesmo controle continua sob o dedo durante a transição.
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('turn-tool-detail-anchor-tool')),
      findsNothing,
    );
    expect(
      tester.getTopLeft(toggle).dy,
      moreOrLessEquals(toggleTop, epsilon: 1),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('A17: a pílula não cobre a coluna de texto', (tester) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(jumpOpacity(tester), 1);

    final pilula = tester.getRect(find.byKey(const ValueKey('jump-to-end')));
    final lista = tester.getRect(find.byType(ListView));

    // Sem mensagem nova a pílula é só o ícone, encostada na direita: quem subiu
    // para reler não pode ter a resposta tapada no meio da tela.
    expect(find.textContaining('NOVA'), findsNothing);
    expect(
      pilula.left,
      greaterThan(lista.center.dx),
      reason: 'centrada, a pílula caía sobre o corpo da resposta',
    );
    expect(pilula.width, lessThan(60), reason: 'sem novidade ela é só o ícone');

    // Com mensagem nova ela abre com a contagem, porque isso vale interromper.
    await tester.pumpWidget(harness(plusOne(threadWith(12))));
    await tester.pumpAndSettle();

    final comContagem = tester.getRect(
      find.byKey(const ValueKey('jump-to-end')),
    );
    expect(find.text('1 NOVA'), findsOneWidget);
    expect(comContagem.width, greaterThan(pilula.width));
    expect(comContagem.left, greaterThan(lista.center.dx));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('o retorno explícito reata o acompanhamento', (tester) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(jumpOpacity(tester), 1);

    await tester.tap(find.byKey(const ValueKey('jump-to-end')));
    await tester.pumpAndSettle();

    final scroll = controllerOf(tester);
    expectAtEnd(scroll);
    final ultimaResposta = find.textContaining('Resposta número 11');
    final viewport = tester.getRect(find.byType(ListView));
    final resposta = tester.getRect(ultimaResposta);
    expect(resposta.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(resposta.bottom, greaterThan(viewport.top));
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('trocar de conversa reata o acompanhamento', (tester) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(jumpOpacity(tester), 1);

    await tester.pumpWidget(
      harness(threadWith(12).copyWith(sessionId: 'sessao-2')),
    );
    await tester.pumpAndSettle();

    expectAtEnd(controllerOf(tester));
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('um novo envio reata o acompanhamento', (tester) async {
    final repository = FakeHermesRepository(
      conversations: const [
        Conversation(id: 'sessao-envio', title: 'Conversa longa'),
      ],
      messages: {
        'sessao-envio': [
          for (var i = 0; i < 12; i++) ...[
            SessionMessage(
              id: 'persisted-u$i',
              role: 'user',
              content: 'Pergunta persistida número $i',
            ),
            SessionMessage(
              id: 'persisted-a$i',
              role: 'assistant',
              content:
                  'Resposta persistida número $i, longa o bastante para '
                  'manter a conversa rolável durante o teste.',
            ),
          ],
        ],
      },
    );
    final container = ProviderContainer(
      overrides: [
        chatLaunchProvider.overrideWithValue(StubChatLaunch()),
        hermesRepositoryProvider.overrideWithValue(repository),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(chatControllerProvider.notifier)
        .openConversation(
          const Conversation(id: 'sessao-envio', title: 'Conversa longa'),
        );

    await tester.pumpWidget(liveHarness(container));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(jumpOpacity(tester), 1);

    final composer = find.descendant(
      of: find.byKey(const ValueKey('composer-field')),
      matching: find.byType(TextField),
    );
    await tester.enterText(composer, 'Continue daqui.');
    await tester.pump();
    await tester.tap(find.byTooltip('Enviar mensagem'));
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Continue daqui.'), findsOneWidget);
    expectAtEnd(controllerOf(tester));
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('quem está no fim continua acompanhando', (tester) async {
    await tester.pumpWidget(harness(threadWith(12)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(harness(plusOne(threadWith(12))));
    await tester.pumpAndSettle();

    final scroll = controllerOf(tester);
    expectAtEnd(scroll);
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a chegada da aprovação continua presa ao fim', (tester) async {
    final state = threadWith(12);
    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();

    await tester.pumpWidget(harness(withApproval(state)));
    await tester.pump();
    for (var frame = 0; frame < 24; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectAtEnd(controllerOf(tester));
    }
    expect(find.byKey(const ValueKey('approval-card')), findsOneWidget);
    expect(jumpOpacity(tester), 0);

    await tester.pumpWidget(const SizedBox());
  });
}
