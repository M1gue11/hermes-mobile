import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';
import 'package:hermes_mobile/main.dart';

import '../support/fake_hermes_repository.dart';
import '../support/fake_gateway_repository.dart';
import '../support/memory_active_run_store.dart';
import '../support/memory_last_conversation_store.dart';

/// A64 visto de fora: o app abre onde a pessoa estava, e voltar para a lista
/// continua sendo uma escolha dela.
void main() {
  Widget app(
    MemoryLastConversationStore store, {
    FakeHermesRepository? repo,
    FakeGatewayRepository? gateway,
    bool forceConversationList = false,
    Uri? initialUri,
  }) => ProviderScope(
    overrides: [
      hermesRepositoryProvider.overrideWithValue(
        repo ?? FakeHermesRepository(),
      ),
      if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
      activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
      lastConversationStoreProvider.overrideWithValue(store),
    ],
    child: HermesApp(
      forceConversationList: forceConversationList,
      initialUri: initialUri,
    ),
  );

  test('normaliza apenas deep links de conversa do Hermes', () {
    expect(
      conversationDeepLinkLocation(
        Uri.parse('hermes://app/chat/session-42?title=Minha%20conversa'),
      ),
      '/chat/session-42?title=Minha%20conversa',
    );
    expect(
      conversationDeepLinkLocation(Uri.parse('/chat/session-42')),
      '/chat/session-42',
    );
    expect(
      conversationDeepLinkLocation(Uri.parse('hermes://outro/chat/session-42')),
      isNull,
    );
    expect(
      conversationDeepLinkLocation(Uri.parse('hermes://app/settings')),
      isNull,
    );
  });

  testWidgets('abre direto na última conversa', (tester) async {
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa persistida',
    );
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();

    expect(find.text('Mensagem persistida'), findsOneWidget);
    expect(find.text('Resposta persistida'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('cold start reidrata a última conversa pelo Dashboard TUI', (
    tester,
  ) async {
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa TUI',
    );
    final gateway = FakeGatewayRepository(
      histories: {
        'session-1': const [
          SessionMessage(id: 'u1', role: 'user', content: 'Antes de fechar'),
          SessionMessage(
            id: 'a1',
            role: 'assistant',
            content: 'Recuperada depois do cold start.',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      app(
        store,
        repo: FakeHermesRepository(messages: const {'session-1': []}),
        gateway: gateway,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Antes de fechar'), findsOneWidget);
    expect(find.text('Recuperada depois do cold start.'), findsOneWidget);
    expect(gateway.historySessionIds, ['session-1']);
    expect(
      gateway.openedSessionIds,
      isEmpty,
      reason: 'carregar histórico não deve adotar uma sessão live',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  // O defeito relatado em 2026-08-15: a lista aparecia e só então o chat
  // deslizava por cima sozinho. Rota inicial não anima, então a conversa tem
  // de estar posicionada já no primeiro quadro em que existe.
  testWidgets('a conversa nasce posicionada, não desliza por cima da lista', (
    tester,
  ) async {
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa persistida',
    );
    await tester.pumpWidget(app(store));
    // Só o suficiente para a decisão local resolver e o roteador nascer.
    for (var i = 0; i < 4; i++) {
      await tester.pump();
    }

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(ChatScreen)).dx,
      0,
      reason: 'entrar animando é exatamente o efeito que se está removendo',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('voltar para a lista não é desfeito pela regra de abertura', (
    tester,
  ) async {
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa persistida',
    );
    await tester.pumpWidget(app(store));
    await tester.pumpAndSettle();
    expect(find.text('Mensagem persistida'), findsOneWidget);

    // Sair do chat é gesto explícito. A abertura automática já decidiu neste
    // processo e não pode empurrar a pessoa de volta.
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Conversas'), findsOneWidget);
    expect(find.text('Mensagem persistida'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('edição de conexão retorna à lista sem reabrir chat sozinha', (
    tester,
  ) async {
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa persistida',
    );
    await tester.pumpWidget(app(store, forceConversationList: true));
    await tester.pumpAndSettle();

    expect(find.text('Conversas'), findsOneWidget);
    expect(find.text('Mensagem persistida'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('deep link prevalece sem criar conversa intermediária', (
    tester,
  ) async {
    final store = MemoryLastConversationStore(
      id: 'session-antiga',
      title: 'Conversa antiga',
    );
    final repository = FakeHermesRepository(
      conversations: [
        Conversation(
          id: 'session-link',
          title: 'Conversa via link',
          model: 'gpt-5.6-terra',
          lastActive: DateTime.now(),
        ),
      ],
      messages: const {
        'session-link': [
          SessionMessage(
            id: 'link-user',
            role: 'user',
            content: 'Aberta pelo endereço.',
          ),
          SessionMessage(
            id: 'link-assistant',
            role: 'assistant',
            content: 'Esta é a conversa correta.',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      app(
        store,
        repo: repository,
        initialUri: Uri.parse(
          'hermes://app/chat/session-link?title=Conversa%20via%20link&'
          'model=gpt-5.6-terra',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aberta pelo endereço.'), findsOneWidget);
    expect(find.text('Esta é a conversa correta.'), findsOneWidget);
    expect(store.value, (id: 'session-link', title: 'Conversa via link'));
    expect(await repository.listConversations(), hasLength(1));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('servidor fora de alcance abre o chat com a falha dele', (
    tester,
  ) async {
    // A abertura não vai à rede para decidir, então ela acerta o lugar mesmo
    // offline. Quem mostra a falha e oferece tentar de novo é o chat.
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa persistida',
    );
    await tester.pumpWidget(
      app(
        store,
        repo: FakeHermesRepository(
          conversationMessagesHandler: (_) =>
              Future<List<Never>>.error(StateError('sem rede')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conversa persistida'), findsOneWidget);
    expect(find.text('Mensagem persistida'), findsNothing);
    expect(
      store.value?.id,
      'session-1',
      reason: 'a lembrança sobrevive à queda',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('retry offline carrega a conversa sem esquecer nem duplicar', (
    tester,
  ) async {
    var offline = true;
    final store = MemoryLastConversationStore(
      id: 'session-1',
      title: 'Conversa persistida',
    );
    final repository = FakeHermesRepository(
      conversationMessagesHandler: (_) => offline
          ? Future<List<SessionMessage>>.error(
              const HermesFailure(HermesFailureKind.semRede),
            )
          : Future<List<SessionMessage>>.value(const [
              SessionMessage(
                id: 'retorno',
                role: 'assistant',
                content: 'A conversa voltou.',
              ),
            ]),
    );

    await tester.pumpWidget(app(store, repo: repository));
    await tester.pumpAndSettle();
    expect(find.text('Sem alcance ao Hermes'), findsOneWidget);

    offline = false;
    await tester.tap(find.byKey(const ValueKey('conversa-falha-retry')));
    await tester.pumpAndSettle();

    expect(find.text('A conversa voltou.'), findsOneWidget);
    expect(store.value?.id, 'session-1');
    expect(await repository.listConversations(), hasLength(1));

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets('primeiro uso abre numa conversa nova, não na lista', (
    tester,
  ) async {
    final store = MemoryLastConversationStore();
    final container = ProviderContainer(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        lastConversationStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const HermesApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('No que estamos trabalhando?'), findsOneWidget);
    expect(container.read(chatControllerProvider).sessionId, isNotNull);
    expect(store.value?.id, container.read(chatControllerProvider).sessionId);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
