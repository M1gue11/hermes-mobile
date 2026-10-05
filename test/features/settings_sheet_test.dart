import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/config/app_settings_store.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/features/chat/widgets/sheets.dart';
import 'package:hermes_mobile/features/settings/agent_persona.dart';
import 'package:hermes_mobile/features/settings/settings_provider.dart';

import '../support/fake_hermes_repository.dart';

class _MemorySettingsStore implements AppSettingsStore {
  StoredAppSettings? value;

  @override
  Future<StoredAppSettings?> read() async => value;

  @override
  Future<void> save(StoredAppSettings settings) async => value = settings;
}

Widget _app(_MemorySettingsStore store) => ProviderScope(
  overrides: [
    appSettingsStoreProvider.overrideWithValue(store),
    hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
  ],
  child: MaterialApp(
    theme: AppTheme.build(),
    home: Scaffold(
      body: Consumer(
        builder: (context, ref, _) => Center(
          child: FilledButton(
            onPressed: () =>
                showSettingsSheet(context, ref, canEditConnections: true),
            child: const Text('Abrir ajustes'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, _MemorySettingsStore store) async {
  await tester.pumpWidget(_app(store));
  await tester.tap(find.text('Abrir ajustes'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ajustes expõe conexões, agente e conversa sem ação destrutiva', (
    tester,
  ) async {
    await _open(tester, _MemorySettingsStore());

    expect(find.text('Conexões'), findsOneWidget);
    expect(find.text('Agente'), findsOneWidget);
    expect(find.text('Conversa'), findsOneWidget);
    expect(find.text('Reconfigurar conexão'), findsNothing);
  });

  testWidgets('persona salva nome com acento e gênero opcional', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    await _open(tester, store);

    await tester.tap(find.text('Agente'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('agent-persona-name')),
      '  Cláudia  ',
    );
    await tester.tap(find.text('Feminino'));
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-agent-persona')),
    );
    await tester.tap(find.byKey(const ValueKey('save-agent-persona')));
    await tester.pumpAndSettle();

    expect(store.value?.agentName, 'Cláudia');
    expect(store.value?.agentGender, AgentGender.feminine.name);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Conexões'), findsOneWidget);
  });

  testWidgets('submenu faz push e a seta volta para Ajustes', (tester) async {
    await _open(tester, _MemorySettingsStore());

    await tester.tap(find.text('Agente'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('agent-persona-name')), findsOneWidget);
    expect(find.byKey(const ValueKey('hermes-sheet-back')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hermes-sheet-back')));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Agente'), findsOneWidget);
    expect(find.byKey(const ValueKey('agent-persona-name')), findsNothing);
  });

  testWidgets('voltar do sistema desempilha submenu antes de fechar Ajustes', (
    tester,
  ) async {
    await _open(tester, _MemorySettingsStore());
    await tester.tap(find.text('Conversa'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Conversa'), findsOneWidget);
    expect(find.text('Mostrar atividade'), findsNothing);
  });

  testWidgets('rota de Conexões volta para o menu ainda aberto', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Center(
                child: FilledButton(
                  onPressed: () =>
                      showSettingsSheet(context, ref, canEditConnections: true),
                  child: const Text('Abrir ajustes'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/settings/connections',
          builder: (context, _) => Scaffold(
            appBar: AppBar(title: const Text('Conexões')),
            body: const Center(child: Text('Editor de conexões')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSettingsStoreProvider.overrideWithValue(store)],
        child: MaterialApp.router(
          theme: AppTheme.build(),
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conexões'));
    await tester.pumpAndSettle();

    expect(find.text('Editor de conexões'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Agente'), findsOneWidget);
  });

  testWidgets('preferências de atividade vivem dentro de Conversa', (
    tester,
  ) async {
    await _open(tester, _MemorySettingsStore());

    await tester.tap(find.text('Conversa'));
    await tester.pumpAndSettle();

    expect(find.text('Mostrar atividade'), findsOneWidget);
    expect(find.text('Consolidado'), findsOneWidget);
    expect(find.text('Cronológico'), findsOneWidget);
    expect(find.text('Contexto da próxima run'), findsOneWidget);
  });

  testWidgets('Contexto empilha sobre Conversa e volta ao submenu', (
    tester,
  ) async {
    await _open(tester, _MemorySettingsStore());
    await tester.tap(find.text('Conversa'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contexto da próxima run'));
    await tester.pumpAndSettle();

    expect(find.text('INSTRUÇÕES DA PRÓXIMA RUN'), findsOneWidget);
    expect(find.byTooltip('Voltar para Conversa'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar para Conversa'));
    await tester.pumpAndSettle();

    expect(find.text('Mostrar atividade'), findsOneWidget);
    expect(find.text('Contexto da próxima run'), findsOneWidget);
  });
}
