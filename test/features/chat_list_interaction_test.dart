import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/config/active_run_store.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_list_screen.dart';
import 'package:hermes_mobile/main.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';
import '../support/stub_chat_launch.dart';

class _FailingRenameRepository extends FakeHermesRepository {
  @override
  Future<Conversation> updateConversation(
    String sessionId, {
    String? title,
  }) async {
    throw const HermesFailure(HermesFailureKind.semRede);
  }
}

void main() {
  testWidgets('linha afunda e recebe tinta ainda durante o toque', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const ChatListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final title = find.text('Conversa persistida');
    final rowScale = find.ancestor(
      of: title,
      matching: find.byType(AnimatedScale),
    );
    final gesture = await tester.startGesture(tester.getCenter(title));
    await tester.pump(const Duration(milliseconds: 160));

    expect(tester.widget<AnimatedScale>(rowScale).scale, lessThan(1));
    final overlays = find.descendant(
      of: rowScale,
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester
          .widgetList<AnimatedContainer>(overlays)
          .any(
            (container) =>
                (container.decoration as BoxDecoration?)?.color !=
                Colors.transparent,
          ),
      isTrue,
    );

    await gesture.cancel();
    await tester.pump(const Duration(milliseconds: 160));
  });

  testWidgets('renomeia conversa e desmonta o diálogo sem exceção', (
    tester,
  ) async {
    final repository = FakeHermesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(repository),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const ChatListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();

    final field = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Nome corrigido');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      (await repository.getConversation('session-1')).title,
      'Nome corrigido',
    );
    expect(find.text('Nome corrigido'), findsOneWidget);
  });

  testWidgets('cancelar renomeação desmonta o diálogo sem alterar a conversa', (
    tester,
  ) async {
    final repository = FakeHermesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(repository),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const ChatListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('rename-conversation-field')),
      'Nome descartado',
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      (await repository.getConversation('session-1')).title,
      'Conversa persistida',
    );
    expect(find.text('Conversa persistida'), findsOneWidget);
  });

  testWidgets('falha ao renomear preserva a lista e oferece orientação', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(
            _FailingRenameRepository(),
          ),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const ChatListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renomear'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('rename-conversation-field')),
      'Nome sem rede',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Conversa persistida'), findsOneWidget);
    expect(
      find.textContaining('Não foi possível alterar a conversa'),
      findsOneWidget,
    );
  });

  testWidgets('abre rota antes de o histórico terminar e hidrata depois', (
    tester,
  ) async {
    final history = Completer<List<SessionMessage>>();
    final repository = FakeHermesRepository(
      conversationMessagesHandler: (_) => history.future,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(repository),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
        child: const HermesApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Conversa persistida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('conversation-opening-spinner')),
      findsOneWidget,
    );
    expect(find.text('ABRINDO CONVERSA'), findsOneWidget);

    history.complete(
      List<SessionMessage>.generate(
        32,
        (index) => SessionMessage(
          id: 'message-after-navigation-$index',
          role: index.isEven ? 'user' : 'assistant',
          content: index == 31
              ? 'Última resposta visível.'
              : 'Mensagem $index com conteúdo suficiente para formar uma '
                    'conversa longa e exigir rolagem real da thread.',
        ),
      ),
    );
    final openingDistancesFromEnd = <double>[];
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final thread = find.byKey(const ValueKey('chat-thread'));
      if (thread.evaluate().isNotEmpty) {
        final position = tester.widget<ListView>(thread).controller!.position;
        openingDistancesFromEnd.add(position.maxScrollExtent - position.pixels);
      }
    }

    final lastResponse = find.text('Última resposta visível.');
    expect(lastResponse, findsOneWidget);
    expect(find.text('ABRINDO CONVERSA'), findsNothing);
    final thread = find.byKey(const ValueKey('chat-thread'));
    final viewport = tester.getRect(thread);
    final lastResponseRect = tester.getRect(lastResponse);
    expect(lastResponseRect.bottom, lessThanOrEqualTo(viewport.bottom));
    expect(lastResponseRect.bottom, greaterThan(viewport.top));
    final scroll = tester.widget<ListView>(thread).controller!;
    expect(
      scroll.offset,
      moreOrLessEquals(scroll.position.maxScrollExtent, epsilon: 1),
    );
    expect(openingDistancesFromEnd, isNotEmpty);
    expect(
      openingDistancesFromEnd.every((distance) => distance.abs() < 1),
      isTrue,
      reason: 'a abertura já deve nascer sincronizada com o fim cronológico',
    );
  });

  testWidgets('restaura e mostra indicador da conversa ativa', (tester) async {
    final activeRuns = MemoryActiveRunStore();
    activeRuns.records['session-1'] = ActiveRunRecord(
      sessionId: 'session-1',
      runId: 'run-1',
      assistantMessageId: 'assistant-1',
      startedAt: DateTime.utc(2026, 8, 11, 9),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
          activeRunStoreProvider.overrideWithValue(activeRuns),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const ChatListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('active-conversation-indicator')),
      findsOneWidget,
    );
    expect(find.text('GERANDO'), findsOneWidget);
  });

  testWidgets('falha tardia aparece no chat e oferece retry quando útil', (
    tester,
  ) async {
    final repository = FakeHermesRepository(
      conversationMessagesHandler: (_) => Future<List<SessionMessage>>.error(
        const HermesFailure(HermesFailureKind.semRede),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(repository),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
        child: const HermesApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Conversa persistida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sem alcance ao Hermes'), findsOneWidget);
    expect(find.byKey(const ValueKey('conversa-falha-retry')), findsOneWidget);
  });
}
