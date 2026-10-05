import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/router/hermes_route_observer.dart';
import 'package:hermes_mobile/core/widgets/unicode_spinner.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_drafts_provider.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';
import 'package:hermes_mobile/main.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';
import '../support/stub_chat_launch.dart';

Future<void> pumpWidgetUntil(
  WidgetTester tester,
  bool Function() condition,
) async {
  for (var index = 0; index < 100; index++) {
    if (condition()) return;
    await tester.pump();
  }
  throw StateError('Condição não atingida a tempo');
}

void main() {
  testWidgets('thread mantém um único spinner global após várias respostas', (
    tester,
  ) async {
    const state = ChatState(
      messages: [
        UserMessage(id: 'user-1', text: 'Primeira pergunta', time: '09:30'),
        AssistantMessage(
          id: 'assistant-1',
          phase: ChatPhase.done,
          text: 'Primeira resposta',
        ),
        UserMessage(id: 'user-2', text: 'Segunda pergunta', time: '09:31'),
        AssistantMessage(
          id: 'assistant-2',
          phase: ChatPhase.cancelled,
          text: 'Segunda resposta',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWithValue(state),
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        ],
        child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(AssistantBubble), findsNWidgets(2));
    // Nenhum turno está em andamento, então a única marca da tela é a cauda.
    expect(find.byType(UnicodeSpinner), findsOneWidget);
    expect(
      find.byKey(const ValueKey('conversation-tail-spinner')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<UnicodeSpinner>(
            find.byKey(const ValueKey('conversation-tail-spinner')),
          )
          .active,
      isTrue,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('enviar mensagem transmite uma resposta na tela', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        ],
        child: const HermesApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.enterText(find.byType(TextField).last, 'Como faço streaming?');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));

    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Como faço streaming?'), findsWidgets);
    expect(find.text('read_file'), findsOneWidget);
    expect(find.text('Resposta real de teste.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('alterna conversas e recria a tela preservando cada rascunho', (
    tester,
  ) async {
    final repository = FakeHermesRepository(
      conversations: const [
        Conversation(id: 'session-1', title: 'Primeira'),
        Conversation(id: 'session-2', title: 'Segunda'),
      ],
      messages: const {'session-1': [], 'session-2': []},
    );
    final container = ProviderContainer(
      overrides: [
        chatLaunchProvider.overrideWithValue(StubChatLaunch()),
        hermesRepositoryProvider.overrideWithValue(repository),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(chatControllerProvider.notifier);

    await controller.openConversation(
      const Conversation(id: 'session-1', title: 'Primeira'),
    );
    await tester.pumpWidget(_chatHarness(container));
    await tester.pump();

    Finder composer() => find.descendant(
      of: find.byKey(const ValueKey('composer-field')),
      matching: find.byType(TextField),
    );

    await tester.enterText(composer(), 'Rascunho da primeira');
    await tester.pump();

    await controller.openConversation(
      const Conversation(id: 'session-2', title: 'Segunda'),
    );
    await tester.pump();
    expect(tester.widget<TextField>(composer()).controller!.text, isEmpty);
    await tester.enterText(composer(), 'Rascunho da segunda');
    await tester.pump();

    await controller.openConversation(
      const Conversation(id: 'session-1', title: 'Primeira'),
    );
    await tester.pump();
    expect(
      tester.widget<TextField>(composer()).controller!.text,
      'Rascunho da primeira',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SizedBox()),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(_chatHarness(container));
    await tester.pump();

    expect(
      tester.widget<TextField>(composer()).controller!.text,
      'Rascunho da primeira',
    );
    expect(
      container.read(chatDraftsProvider.notifier).draftFor('session-2'),
      'Rascunho da segunda',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('Enter preserva quebra de linha e somente o botão envia', (
    tester,
  ) async {
    final repository = FakeHermesRepository(
      conversations: const [Conversation(id: 'session-1', title: 'Primeira')],
      messages: {'session-1': []},
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
          const Conversation(id: 'session-1', title: 'Primeira'),
        );
    await tester.pumpWidget(_chatHarness(container));
    await tester.pump();

    final composer = find.descendant(
      of: find.byKey(const ValueKey('composer-field')),
      matching: find.byType(TextField),
    );
    final field = tester.widget<TextField>(composer);
    expect(field.keyboardType, TextInputType.multiline);
    expect(field.textInputAction, TextInputAction.newline);
    expect(field.onSubmitted, isNull);

    const message = 'Primeira linha\nSegunda linha';
    await tester.enterText(composer, message);
    await tester.pump();

    expect(tester.widget<TextField>(composer).controller!.text, message);
    expect(await repository.conversationMessages('session-1'), isEmpty);
    expect(container.read(chatControllerProvider).sessionId, 'session-1');
    expect(container.read(chatControllerProvider).streaming, isFalse);

    await tester.tap(find.byTooltip('Enviar mensagem'));
    for (var index = 0; index < 4; index++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(
      container
          .read(chatControllerProvider)
          .messages
          .whereType<UserMessage>()
          .map((item) => item.text),
      contains(message),
    );
    final persisted = await repository.conversationMessages('session-1');
    expect(persisted.first.content, message);
    expect(tester.widget<TextField>(composer).controller!.text, isEmpty);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('lifecycle e saída da rota pausam e retomam o listener', (
    tester,
  ) async {
    final stream = ControlledRunStream();
    final repository = FakeHermesRepository(
      controlledStreams: [stream],
      runSnapshots: const [Run(runId: 'ignored', status: RunStatus.running)],
    );
    final container = ProviderContainer(
      overrides: [
        chatLaunchProvider.overrideWithValue(StubChatLaunch()),
        hermesRepositoryProvider.overrideWithValue(repository),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(() {
      if (tester.binding.lifecycleState == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      }
      if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
      }
      if (tester.binding.lifecycleState == AppLifecycleState.inactive) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      }
    });
    final controller = container.read(chatControllerProvider.notifier);
    await controller.newChat();
    await controller.send('Continue mesmo sem foco.');
    await pumpWidgetUntil(tester, () => stream.listenCount == 1);

    await tester.pumpWidget(_chatHarness(container));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pumpWidgetUntil(tester, () => stream.cancelCount == 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpWidgetUntil(tester, () => stream.listenCount == 2);

    final chatContext = tester.element(find.byType(ChatScreen));
    Navigator.of(chatContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Outra rota')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await pumpWidgetUntil(tester, () => stream.cancelCount == 2);
    Navigator.of(chatContext).pop();
    await tester.pump(const Duration(milliseconds: 400));
    await pumpWidgetUntil(tester, () => stream.listenCount == 3);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

Widget _chatHarness(ProviderContainer container) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp(
    theme: AppTheme.build(),
    navigatorObservers: [hermesRouteObserver],
    home: const ChatScreen(),
  ),
);
