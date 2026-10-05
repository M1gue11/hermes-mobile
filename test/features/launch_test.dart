import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/last_conversation_store.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/conversation_actions_provider.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import '../support/memory_last_conversation_store.dart';

Future<void> pumpUntil(bool Function() condition, {int max = 8000}) async {
  for (var index = 0; index < max; index++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Condição não atingida a tempo');
}

/// A64: o app abre onde a pessoa estava. O que estes testes protegem não é o
/// caminho feliz, é o contrário: não criar sessão duplicada, não ir à rede na
/// abertura de todo dia, não apagar a lembrança por causa de rede, e não
/// decidir duas vezes no mesmo processo.
void main() {
  ({ProviderContainer container, MemoryLastConversationStore store}) montar({
    String? guardado,
    String titulo = 'Conversa persistida',
    Object? readFailure,
    FakeHermesRepository? repository,
  }) {
    final store = MemoryLastConversationStore(
      id: guardado,
      title: titulo,
      readFailure: readFailure,
    );
    final container = ProviderContainer(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(
          repository ?? FakeHermesRepository(),
        ),
        lastConversationStoreProvider.overrideWithValue(store),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, store: store);
  }

  test('sem id guardado, o launch cria uma conversa e abre o chat', () async {
    final (:container, :store) = montar();

    final outcome = await container.read(chatLaunchProvider).resolve();

    expect(outcome, ChatLaunchOutcome.abrirChat);
    final sessionId = container.read(chatControllerProvider).sessionId;
    expect(sessionId, isNotNull);
    expect(store.value?.id, sessionId, reason: 'o novo lugar já fica lembrado');
  });

  test('id guardado reabre a conversa sem consultar a lista', () async {
    final repository = FakeHermesRepository();
    final (:container, :store) = montar(
      guardado: 'session-1',
      repository: repository,
    );

    final outcome = await container.read(chatLaunchProvider).resolve();

    // A rota já nasce certa: a decisão é local e não espera nada de rede, que
    // é o que fazia a lista aparecer antes do chat.
    expect(outcome, ChatLaunchOutcome.abrirChat);
    final state = container.read(chatControllerProvider);
    expect(state.sessionId, 'session-1');
    expect(state.title, 'Conversa persistida');
    expect(state.openingConversation, isTrue);

    await pumpUntil(
      () => !container.read(chatControllerProvider).openingConversation,
    );
    expect(container.read(chatControllerProvider).messages, hasLength(2));
  });

  test('servidor fora de alcance não esquece o lugar', () async {
    // Apagar aqui seria perder para sempre a última conversa por causa de uma
    // queda de rede. O chat mostra a falha e oferece tentar de novo.
    final (:container, :store) = montar(
      guardado: 'session-1',
      repository: FakeHermesRepository(
        conversationMessagesHandler: (_) =>
            Future<List<Never>>.error(StateError('sem rede')),
      ),
    );

    await container.read(chatLaunchProvider).resolve();
    await pumpUntil(
      () =>
          container.read(chatControllerProvider).conversationLoadFailure !=
          null,
    );

    expect(store.value?.id, 'session-1');
  });

  test('conversa apagada no servidor é esquecida', () async {
    final (:container, :store) = montar(
      guardado: 'session-1',
      repository: FakeHermesRepository(
        conversationMessagesHandler: (_) => Future<List<Never>>.error(
          const HermesFailure(HermesFailureKind.naoEncontrado, statusCode: 404),
        ),
      ),
    );

    await container.read(chatLaunchProvider).resolve();
    await pumpUntil(() => store.writes.contains(null));

    expect(store.value, isNull, reason: 'o próximo launch começa limpo');
  });

  test('armazenamento ilegível não trava a abertura do app', () async {
    final (:container, :store) = montar(
      readFailure: StateError('keystore indisponível'),
    );

    expect(
      await container.read(chatLaunchProvider).resolve(),
      ChatLaunchOutcome.abrirChat,
    );
  });

  test('a decisão vale uma vez por processo', () async {
    final (:container, :store) = montar();
    final launch = container.read(chatLaunchProvider);

    expect(launch.decidiu, isFalse);
    await launch.resolve();
    final primeira = container.read(chatControllerProvider).sessionId;
    expect(launch.decidiu, isTrue);

    // Rebuild, volta de background e reidratação caem aqui. Nenhum deles pode
    // criar sessão nova nem arrastar de volta para o chat.
    await launch.resolve();
    await launch.resolve();

    expect(container.read(chatControllerProvider).sessionId, primeira);
    expect(
      store.writes.whereType<LastConversation>(),
      hasLength(1),
      reason: 'uma sessão só, por mais que o launch seja consultado',
    );
  });

  test('apagar a conversa lembrada esquece o lugar', () async {
    final (:container, :store) = montar(guardado: 'session-1');

    await container
        .read(conversationActionsProvider.notifier)
        .delete('session-1');

    expect(store.value, isNull);
  });

  test('apagar outra conversa preserva o lugar lembrado', () async {
    final (:container, :store) = montar(guardado: 'session-1');

    await container
        .read(conversationActionsProvider.notifier)
        .delete('session-2');

    expect(store.value?.id, 'session-1');
  });

  test('abrir uma conversa pela lista passa a ser o lugar lembrado', () async {
    final (:container, :store) = montar(guardado: 'session-1');

    await container
        .read(chatControllerProvider.notifier)
        .openConversation(const Conversation(id: 'session-2', title: 'Outra'));

    expect(store.value, (id: 'session-2', title: 'Outra'));
  });
}
