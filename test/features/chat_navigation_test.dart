import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/health_status.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import '../support/stub_chat_launch.dart';

const _conversation = Conversation(
  id: 'navigation-session',
  title: 'Planejamento do projeto',
  model: 'modelo-com-identificador-muito-longo-para-um-celular',
  inputTokens: 1200,
  outputTokens: 300,
  actualCostUsd: 0.04,
);

class _Harness {
  _Harness({FakeHermesRepository? repository, this.connections = false})
    : container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          hermesRepositoryProvider.overrideWithValue(
            repository ??
                FakeHermesRepository(
                  conversations: const [_conversation],
                  messages: {
                    _conversation.id: [
                      for (var i = 0; i < 25; i++)
                        SessionMessage(
                          id: 'message-$i',
                          role: 'assistant',
                          content: 'Resposta $i com detalhes do trabalho. ' * 8,
                        ),
                    ],
                  },
                ),
          ),
          gatewayRepositoryProvider.overrideWithValue(FakeGatewayRepository()),
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        ],
      ) {
    router = buildAppRouter(
      initialLocation: '/chat',
      connectionSettingsBuilder: connections
          ? (_) => const Scaffold(body: Text('Editar conexões'))
          : null,
    );
    addTearDown(router.dispose);
    addTearDown(container.dispose);
  }

  final bool connections;
  final ProviderContainer container;
  late final GoRouter router;

  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await container
        .read(chatControllerProvider.notifier)
        .openConversation(_conversation);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.build(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

Finder _composer() => find.descendant(
  of: find.byKey(const ValueKey('composer-field')),
  matching: find.byType(TextField),
);

void main() {
  for (final (label, route) in [
    ('Acessos', '/pairing'),
    ('Uso geral', '/usage'),
    ('Agendamentos', '/jobs'),
    ('Servidor', '/server'),
  ]) {
    testWidgets(
      '$label abre pelo chat e volta sem menu, perda de leitura ou rascunho',
      (tester) async {
        final harness = _Harness();
        await harness.open(tester);
        await tester.enterText(_composer(), 'Rascunho preservado');
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        final thread = tester.widget<ListView>(find.byType(ListView).first);
        await tester.drag(find.byType(ListView).first, const Offset(0, 400));
        await tester.pumpAndSettle();
        final offset = thread.controller!.offset;

        await tester.tap(find.byTooltip('Operar Hermes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(harness.router.state.uri.path, route);
        expect(find.byKey(const ValueKey('hermes-sheet-title')), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(harness.router.state.uri.path, '/chat');
        expect(
          tester.widget<TextField>(_composer()).controller!.text,
          'Rascunho preservado',
        );
        expect(thread.controller!.offset, closeTo(offset, 1));
        expect(find.byKey(const ValueKey('hermes-sheet-title')), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('Recursos abre ferramentas com o alcance da mudança explícito', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.open(tester);
    await tester.tap(find.text('Recursos'));
    await tester.pumpAndSettle();
    expect(
      find.text('Configurar o perfil para novas conversas'),
      findsOneWidget,
    );
    await tester.tap(find.text('Ferramentas e MCP'));
    await tester.pumpAndSettle();
    expect(harness.router.state.uri.path, '/tools');
    expect(find.textContaining('A conversa aberta mantém'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hermes-sheet-title')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('instruções salvam para o próximo turno e voltam para Recursos', (
    tester,
  ) async {
    final harness = _Harness();
    await harness.open(tester);
    await tester.tap(find.text('Recursos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instruções do próximo turno'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Voltar para Recursos'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField).last,
      'Responda em português.',
    );
    await tester.ensureVisible(find.text('Salvar instruções'));
    await tester.tap(find.text('Salvar instruções'));
    await tester.pumpAndSettle();
    expect(
      harness.container.read(chatControllerProvider).instructions,
      'Responda em português.',
    );
    expect(find.text('Skills'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'título abre uso registrado da conversa sem inventar medidor vivo',
    (tester) async {
      final harness = _Harness();
      await harness.open(tester);
      await tester.tap(find.byTooltip('Detalhes da conversa'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes da conversa'), findsOneWidget);
      expect(find.text('Tokens de entrada'), findsOneWidget);
      expect(find.text('1200'), findsOneWidget);
      expect(find.text('300'), findsOneWidget);
      expect(find.text('Custo real'), findsOneWidget);
      expect(find.text('Uso geral'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Ajustes acessíveis pelo chat mantêm edição de conexões', (
    tester,
  ) async {
    final harness = _Harness(connections: true);
    await harness.open(tester);
    await tester.tap(find.byTooltip('Operar Hermes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes do aplicativo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conexões'));
    await tester.pumpAndSettle();
    expect(find.text('Editar conexões'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'tela estreita e texto ampliado acomodam modelo longo e os dois menus',
    (tester) async {
      final harness = _Harness();
      await harness.open(tester, scale: 2);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('composer-resources'))).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('Recursos'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Operar Hermes'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ajustes do aplicativo'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'consulta de API pendente e falha não se apresentam como offline',
    (tester) async {
      final api = _PendingHealthRepository();
      final harness = _Harness(repository: api);
      await harness.open(tester);
      expect(find.text('Verificando API…'), findsOneWidget);
      api.healthResult.completeError(StateError('indisponível'));
      await tester.pumpAndSettle();
      expect(find.text('Falha ao verificar API'), findsOneWidget);
      expect(find.textContaining('offline'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _PendingHealthRepository extends FakeHermesRepository {
  final healthResult = Completer<HealthStatus>();

  @override
  Future<HealthStatus> health() => healthResult.future;
}
