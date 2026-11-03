import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/gateway_command.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/gateway_commands_provider.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import '../support/stub_chat_launch.dart';

const _session = Conversation(
  id: 'session-1',
  title: 'Projeto em andamento',
  model: 'modelo',
);

GatewayCommandCatalog _catalog() => GatewayCommandCatalog.fromJson({
  'pairs': [
    ['/status', 'Consultar o estado da sessão'],
    ['/stop', 'Interromper a resposta'],
    ['/undo', 'Desfazer turno'],
    ['/compress', 'Compactar contexto'],
    ['/work', 'Executar a Skill'],
    ['/custom', 'Comando personalizado'],
    ['/prompt', 'Preparar texto'],
    ['/new', 'Nova conversa'],
    ['/quit', 'Sair do terminal'],
  ],
  'categories': [
    {
      'name': 'User commands',
      'pairs': [
        ['/custom', 'Comando personalizado'],
      ],
    },
  ],
  'skills': {
    '/work': {'usage': 1},
  },
  'commands': {
    '/model': {'desktop': 'hidden'},
    '/quit': {'desktop': 'terminal'},
  },
});

class _Harness {
  _Harness({bool paired = true}) {
    turn.catalog = _catalog();
    turn.completions = const GatewaySlashCompletions(
      items: [(text: 'status', description: 'Estado da sessão')],
    );
    gateway = FakeGatewayRepository(paired: paired, turns: [turn]);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        hermesRepositoryProvider.overrideWithValue(api),
        gatewayRepositoryProvider.overrideWithValue(gateway),
        activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
        chatLaunchProvider.overrideWithValue(StubChatLaunch()),
      ],
    );
    addTearDown(() {
      if (!_disposed) container.dispose();
    });
  }
  final api = FakeHermesRepository(
    conversations: const [
      _session,
      Conversation(id: 'session-2', title: 'Outra'),
    ],
    messages: const {
      'session-1': [
        SessionMessage(id: 'u1', role: 'user', content: 'Mensagem existente'),
      ],
      'session-2': [],
    },
  );
  final turn = FakeGatewayLiveTurn(
    storedSessionId: 'session-1',
    liveSessionId: 'live-1',
    running: false,
    initialHistory: const [
      SessionMessage(id: 'u1', role: 'user', content: 'Mensagem existente'),
    ],
  );
  late final FakeGatewayRepository gateway;
  late final ProviderContainer container;
  bool _disposed = false;
  ChatController get chat => container.read(chatControllerProvider.notifier);
  GatewayCommands get actions =>
      container.read(gatewayCommandsProvider.notifier);
  Future<void> open(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await chat.openConversation(_session);
    final router = buildAppRouter(initialLocation: '/chat');
    addTearDown(router.dispose);
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

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    _disposed = true;
    await tester.pump(const Duration(milliseconds: 1));
  }
}

Finder _input() => find.descendant(
  of: find.byKey(const ValueKey('composer-field')),
  matching: find.byType(TextField),
);
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(_input(), text);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _send(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('composer-send')));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets(
    'Recursos oferece catálogo real e seleção preserva o rascunho para revisão',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      await _type(tester, 'meu texto');
      await tester.tap(find.text('Recursos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comandos'));
      await tester.pumpAndSettle();
      expect(find.text('/status'), findsOneWidget);
      await tester.tap(find.text('/status'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(_input()).controller!.text,
        '/status meu texto',
      );
      expect(h.turn.executedCommands, isEmpty);
      await h.close(tester);
    },
  );

  testWidgets('sugestão substitui apenas o token e não executa o comando', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    await _type(tester, '/sta');
    await tester.tap(find.text('/status'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(_input()).controller!.text, '/status ');
    expect(h.turn.executedCommands, isEmpty);
    await h.close(tester);
  });

  testWidgets(
    'consulta mostra resultado e histórico local sem prompt nem perda de conversa',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      h.turn.commandHandler = (_) async => const GatewayCommandResult(
        kind: GatewayCommandResultKind.output,
        output: 'Servidor ativo',
      );
      await _type(tester, '/status');
      await _send(tester);
      expect(find.text('Servidor ativo'), findsOneWidget);
      expect(h.turn.executedCommands, ['/status']);
      expect(h.turn.submitted, isEmpty);
      expect(h.api.historicos, isEmpty);
      expect(
        h.container.read(gatewayCommandsProvider).history.single.command,
        '/status',
      );
      expect(
        h.container
            .read(chatControllerProvider)
            .messages
            .whereType<UserMessage>()
            .single
            .text,
        'Mensagem existente',
      );
      await h.close(tester);
    },
  );

  testWidgets('compactação pendente sem saída nunca aparece como concluída', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    h.turn.commandHandler = (_) async => const GatewayCommandResult(
      kind: GatewayCommandResultKind.output,
      status: 'pending',
    );
    await _type(tester, '/compress');
    await _send(tester);
    await tester.tap(find.text('Executar'));
    await tester.pumpAndSettle();
    final record = h.container.read(gatewayCommandsProvider).history.single;
    expect(record.output, contains('Ação em andamento no Hermes.'));
    expect(record.output, isNot(contains('concluído')));
    expect(find.text(record.output), findsOneWidget);
    expect(h.turn.executedCommands, ['/compress']);
    expect(h.turn.submitted, isEmpty);
    expect(h.api.historicos, isEmpty);
    await h.close(tester);
  });

  testWidgets('cancelar alteração preserva comando e não chama execução', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    await _type(tester, '/undo');
    await _send(tester);
    expect(find.text('Executar comando?'), findsOneWidget);
    expect(
      find.text('Remove turnos do histórico desta conversa.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(h.turn.executedCommands, isEmpty);
    expect(tester.widget<TextField>(_input()).controller!.text, '/undo');
    await _send(tester);
    await tester.tap(find.text('Executar'));
    await tester.pumpAndSettle();
    expect(h.turn.executedCommands, ['/undo']);
    await h.close(tester);
  });

  testWidgets('desfazer atualiza histórico e prepara texto sem reenviar', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    h.turn.commandHistoryHandler = () async => [];
    h.turn.commandHandler = (_) async => const GatewayCommandResult(
      kind: GatewayCommandResultKind.prefill,
      message: 'Texto preparado\n\npara revisar',
    );
    await _type(tester, '/undo');
    await _send(tester);
    await tester.tap(find.text('Executar'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(_input()).controller!.text,
      'Texto preparado\n\npara revisar',
    );
    expect(h.turn.submitted, isEmpty);
    expect(h.container.read(chatControllerProvider).messages, isEmpty);
    await h.close(tester);
  });

  testWidgets(
    'Skill submete uma vez no mesmo canal e mostra só a invocação humana',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      h.turn.commandHandler = (_) async => const GatewayCommandResult(
        kind: GatewayCommandResultKind.skill,
        message: 'CORPO EXPANDIDO QUE SÓ O MODELO RECEBE',
        display: '/work revisar',
      );
      await _type(tester, '/work revisar');
      await _send(tester);
      expect(
        h.turn.submitted,
        ['CORPO EXPANDIDO QUE SÓ O MODELO RECEBE'],
        reason:
            'A Skill deve enviar um único prompt no mesmo canal de comandos.',
      );
      expect(h.gateway.openedSessionIds, ['session-1']);
      expect(find.text('/work revisar'), findsOneWidget);
      expect(find.textContaining('CORPO EXPANDIDO'), findsNothing);
      expect(h.api.historicos, isEmpty);
      await h.close(tester);
    },
  );

  testWidgets('recusa do servidor não vira prompt nem limpa o comando', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    h.turn.commandHandler = (_) async => throw const GatewayOperationException(
      'Comando indisponível.',
      code: 4018,
    );
    await _type(tester, '/status');
    await _send(tester);
    expect(find.text('Comando indisponível.'), findsOneWidget);
    expect(tester.widget<TextField>(_input()).controller!.text, '/status');
    expect(h.turn.submitted, isEmpty);
    expect(h.api.historicos, isEmpty);
    await h.close(tester);
  });

  testWidgets(
    'alias mantém argumentos multilinha em cada etapa e detecta ciclo',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      h.turn.commandHandler = (raw) async => raw.startsWith('/custom')
          ? const GatewayCommandResult(
              kind: GatewayCommandResultKind.alias,
              target: '/second prefix',
            )
          : raw.startsWith('/second')
          ? const GatewayCommandResult(
              kind: GatewayCommandResultKind.alias,
              target: '/status',
            )
          : const GatewayCommandResult(
              kind: GatewayCommandResultKind.output,
              output: 'OK',
            );
      await h.actions.execute('/custom linha 1\n\n linha 2', confirmed: true);
      expect(h.turn.executedCommands, [
        '/custom linha 1\n\n linha 2',
        '/second prefix linha 1\n\n linha 2',
        '/status prefix linha 1\n\n linha 2',
      ]);
      h.turn.commandHandler = (_) async => const GatewayCommandResult(
        kind: GatewayCommandResultKind.alias,
        target: '/custom',
      );
      await expectLater(
        h.actions.execute('/custom', confirmed: true),
        throwsA(isA<GatewayOperationException>()),
      );
      await h.close(tester);
    },
  );

  testWidgets(
    'comando em voo bloqueia duplo toque e resposta perdida não reexecuta',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      final pending = Completer<GatewayCommandResult>();
      h.turn.commandHandler = (_) => pending.future;
      final first = h.actions.execute('/status');
      await tester.pump();
      await expectLater(
        h.actions.execute('/status'),
        throwsA(isA<GatewayOperationException>()),
      );
      pending.completeError(TimeoutException('reply lost'));
      await expectLater(first, throwsA(isA<GatewayOperationException>()));
      expect(h.turn.executedCommands, ['/status']);
      await expectLater(
        h.actions.execute('/status'),
        throwsA(isA<CommandConfirmationRequired>()),
      );
      expect(h.turn.executedCommands, ['/status']);
      await h.close(tester);
    },
  );

  testWidgets(
    'troca de conversa durante comando guarda resultado na origem sem enviar na outra',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      final pending = Completer<GatewayCommandResult>();
      h.turn.commandHandler = (_) => pending.future;
      final command = h.actions.execute('/status');
      await tester.pump();
      final changing = h.chat.openConversation(
        const Conversation(id: 'session-2', title: 'Outra'),
      );
      await tester.pump();
      expect(h.container.read(chatControllerProvider).sessionId, 'session-2');
      pending.complete(
        const GatewayCommandResult(
          kind: GatewayCommandResultKind.output,
          output: 'Resultado da origem',
        ),
      );
      var finished = false;
      final both = Future.wait([
        changing,
        command,
      ]).then((_) => finished = true);
      for (var i = 0; i < 20 && !finished; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(
        finished,
        isTrue,
        reason:
            'A troca e o resultado do comando devem concluir sem depender um do outro.',
      );
      await both;
      expect(h.container.read(chatControllerProvider).sessionId, 'session-2');
      expect(
        h.container.read(gatewayCommandsProvider).history.single.sessionId,
        'session-1',
      );
      expect(h.turn.submitted, isEmpty);
      await h.close(tester);
    },
  );

  testWidgets(
    'catálogo e sugestões com texto ampliado cabem e explicam terminal indisponível',
    (tester) async {
      final h = _Harness();
      await h.open(tester, scale: 2);
      await _type(tester, '/sta');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Todos os comandos'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('gateway-command-search')),
        'quit',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Este comando depende da interface do computador.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await h.close(tester);
    },
  );

  testWidgets(
    'consulta slash durante streaming usa o canal ativo e não aciona Parar',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      final submitted = h.chat.send('Pergunta inicial');
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(await submitted, isTrue);
      await _type(tester, '/status');
      expect(find.byTooltip('Executar comando'), findsOneWidget);
      await _send(tester);
      expect(h.turn.executedCommands, ['/status']);
      expect(h.turn.submitted, ['Pergunta inicial']);
      expect(h.turn.interrupted, isFalse);
      expect(h.container.read(chatControllerProvider).streaming, isTrue);
      await h.actions.execute('/stop');
      expect(h.turn.interrupted, isTrue);
      expect(h.turn.executedCommands, ['/status']);
      await h.close(tester);
    },
  );

  testWidgets('autocomplete de argumento preserva emoji e o comando anterior', (
    tester,
  ) async {
    final h = _Harness();
    await h.open(tester);
    h.turn.completions = GatewaySlashCompletions(
      items: const [(text: 'pending', description: 'Pendentes')],
      replaceFrom: '/goal 🦊 '.runes.length,
    );
    await _type(tester, '/goal 🦊 pe');
    await tester.tap(find.text('pending'));
    await tester.pump();
    expect(
      tester.widget<TextField>(_input()).controller!.text,
      '/goal 🦊 pending ',
    );
    expect(h.turn.executedCommands, isEmpty);
    await h.close(tester);
  });

  testWidgets(
    'modelo sem argumentos abre o seletor nativo sem executar um RPC de alteração',
    (tester) async {
      final h = _Harness();
      await h.open(tester);
      final outcome = await h.actions.execute('/model');
      expect(outcome.action, CommandClientAction.model);
      expect(h.turn.executedCommands, isEmpty);
      await h.close(tester);
    },
  );

  testWidgets('sem Dashboard oferece conexão e não cria sessão de execução', (
    tester,
  ) async {
    final h = _Harness(paired: false);
    await h.open(tester);
    await tester.tap(find.text('Recursos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comandos'));
    await tester.pumpAndSettle();
    expect(find.text('Conectar Dashboard'), findsOneWidget);
    expect(h.gateway.openedSessionIds, isEmpty);
    expect(h.api.historicos, isEmpty);
    await h.close(tester);
  });
}
