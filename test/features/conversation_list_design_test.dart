import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/config/active_run_store.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_list_screen.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

Widget _harness({
  required List<Conversation> conversations,
  MemoryActiveRunStore? activeRuns,
  double textScale = 1,
}) {
  return ProviderScope(
    overrides: [
      hermesRepositoryProvider.overrideWithValue(
        FakeHermesRepository(conversations: conversations),
      ),
      activeRunStoreProvider.overrideWithValue(
        activeRuns ?? MemoryActiveRunStore(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.build(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: const ChatListScreen(),
    ),
  );
}

void main() {
  testWidgets('cada data forma um grupo e separa os dias visualmente', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final earlier = today.subtract(const Duration(days: 2));
    final conversations = [
      Conversation(
        id: 'today-1',
        title: 'Primeira de hoje',
        lastActive: today.add(const Duration(hours: 12)),
      ),
      Conversation(
        id: 'today-2',
        title: 'Segunda de hoje',
        lastActive: today.add(const Duration(hours: 9)),
      ),
      Conversation(
        id: 'yesterday-1',
        title: 'Conversa de ontem',
        lastActive: yesterday.add(const Duration(hours: 18)),
      ),
      Conversation(
        id: 'earlier-1',
        title: 'Primeira do dia anterior',
        lastActive: earlier.add(const Duration(hours: 16)),
      ),
      Conversation(
        id: 'earlier-2',
        title: 'Segunda do dia anterior',
        lastActive: earlier.add(const Duration(hours: 8)),
      ),
    ];

    await tester.pumpWidget(_harness(conversations: conversations));
    await tester.pumpAndSettle();

    expect(find.text('HOJE'), findsOneWidget);
    expect(find.text('ONTEM'), findsOneWidget);
    expect(
      find.byKey(ValueKey('conversation-group-${_dateKey(earlier)}')),
      findsOneWidget,
    );

    final first = tester.getRect(
      find.byKey(const ValueKey('conversation-row-today-1')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('conversation-row-today-2')),
    );
    final nextDay = tester.getRect(
      find.byKey(const ValueKey('conversation-row-yesterday-1')),
    );
    expect(second.top - first.bottom, lessThanOrEqualTo(2));
    expect(nextDay.top - second.bottom, greaterThan(24));
  });

  testWidgets(
    'busca e filtros começam recolhidos e preservam seleção visível',
    (tester) async {
      final now = DateTime.now();
      final conversations = [
        Conversation(
          id: 'api',
          title: 'Planejar API',
          preview: 'Contrato do servidor',
          source: 'api_server',
          lastActive: now,
        ),
        Conversation(
          id: 'telegram',
          title: 'Responder Telegram',
          preview: 'Mensagem recebida',
          source: 'telegram',
          lastActive: now,
        ),
      ];

      await tester.pumpWidget(_harness(conversations: conversations));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('conversation-search-panel')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('conversation-discovery-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('conversation-search-panel')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('conversation-search-field')),
        'Telegram',
      );
      await tester.pump();
      expect(find.text('Responder Telegram'), findsOneWidget);
      expect(find.text('Planejar API'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('conversation-discovery-toggle')),
      );
      await tester.pumpAndSettle();
      expect(find.text('“Telegram”'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('conversation-discovery-clear')),
        findsOneWidget,
      );
    },
  );

  testWidgets('modelo e estado ativo convivem sem perder o detalhe completo', (
    tester,
  ) async {
    final activeRuns = MemoryActiveRunStore();
    activeRuns.records['active'] = ActiveRunRecord(
      sessionId: 'active',
      runId: 'run-1',
      assistantMessageId: 'assistant-1',
      startedAt: DateTime.now(),
    );
    final conversations = [
      Conversation(
        id: 'active',
        title: 'Trabalho em andamento',
        preview: 'Executando as ferramentas necessárias',
        model: 'gpt-5.6-terra',
        provider: 'openai-codex',
        lastActive: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(
      _harness(conversations: conversations, activeRuns: activeRuns),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('5.6 TERRA'), findsOneWidget);
    expect(find.text('GERANDO'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detalhes'));
    await tester.pumpAndSettle();
    expect(find.text('gpt-5.6-terra'), findsOneWidget);
    expect(find.text('openai-codex'), findsOneWidget);
  });

  testWidgets('texto ampliado empilha metadados sem overflow', (tester) async {
    final activeRuns = MemoryActiveRunStore();
    activeRuns.records['active'] = ActiveRunRecord(
      sessionId: 'active',
      runId: 'run-1',
      assistantMessageId: 'assistant-1',
      startedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      _harness(
        textScale: 1.6,
        activeRuns: activeRuns,
        conversations: [
          Conversation(
            id: 'active',
            title: 'Título longo que precisa continuar legível',
            preview:
                'Preview longo que não pode empurrar os metadados para fora',
            model: 'gpt-5.6-terra',
            lastActive: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('5.6 TERRA'), findsOneWidget);
    expect(find.text('GERANDO'), findsOneWidget);
  });

  testWidgets('controles principais respeitam alvo Android de 48 dp', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        conversations: [
          Conversation(
            id: 'one',
            title: 'Conversa',
            lastActive: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('botao-maquina'))),
      const Size(48, 48),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('conversation-discovery-toggle')))
          .height,
      48,
    );
  });
}
