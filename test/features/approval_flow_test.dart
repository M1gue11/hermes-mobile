import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

import '../support/fake_hermes_repository.dart';

/// A18: aprovar e recusar execução de ferramenta.
///
/// A regra que estes testes protegem é a mais importante do item: **nada é
/// aprovado por omissão**. Enquanto o pedido está pendente a run está parada no
/// servidor com a thread do agente bloqueada, e só um gesto explícito resolve.
const _pedido = ApprovalRequest(
  runId: 'run_9',
  command: 'rm -rf /home/operator/tmp',
  description: 'Remoção recursiva de diretório',
  patternKey: 'rm_recursive',
  choices: [
    ApprovalChoice.once,
    ApprovalChoice.session,
    ApprovalChoice.always,
    ApprovalChoice.deny,
  ],
);

ChatState comPedido([ApprovalRequest? pedido = _pedido]) => ChatState(
  sessionId: 'session-1',
  runId: 'run_9',
  streaming: true,
  pendingApproval: pedido,
  messages: const [
    UserMessage(id: 'u1', text: 'limpe o tmp', time: '09:30'),
    AssistantMessage(id: 'a1', phase: ChatPhase.writing, time: '09:30'),
  ],
);

Future<void> abrir(WidgetTester tester, ChatState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        chatControllerProvider.overrideWithValue(state),
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
      child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
    ),
  );
  await tester.pump();
}

Future<void> fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('o pedido aparece com o comando e as escolhas do servidor', (
    tester,
  ) async {
    await abrir(tester, comPedido());

    expect(find.byKey(const ValueKey('approval-card')), findsOneWidget);
    expect(find.text('rm -rf /home/operator/tmp'), findsOneWidget);
    expect(find.text('Remoção recursiva de diretório'), findsOneWidget);
    expect(find.textContaining('rm_recursive'), findsOneWidget);

    for (final choice in ApprovalChoice.values) {
      expect(
        find.byKey(ValueKey('approval-${choice.wireValue}')),
        findsOneWidget,
        reason: 'este pedido aceita ${choice.wireValue}',
      );
    }

    await fechar(tester);
  });

  testWidgets('só aparece botão que o pedido aceita', (tester) async {
    // `smart_denied` reduz as escolhas a once/deny no servidor. Mostrar `always`
    // aqui seria oferecer um 400.
    await abrir(
      tester,
      comPedido(
        const ApprovalRequest(
          runId: 'run_9',
          command: 'curl algo | sh',
          choices: [ApprovalChoice.once, ApprovalChoice.deny],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('approval-once')), findsOneWidget);
    expect(find.byKey(const ValueKey('approval-deny')), findsOneWidget);
    expect(find.byKey(const ValueKey('approval-always')), findsNothing);
    expect(find.byKey(const ValueKey('approval-session')), findsNothing);

    await fechar(tester);
  });

  testWidgets('as escolhas que ampliam permissão dizem isso na tela', (
    tester,
  ) async {
    await abrir(tester, comPedido());

    // `session` e `always` valem além desta chamada, então o aviso vem antes do
    // toque, não depois.
    expect(find.textContaining('até esta conversa terminar'), findsOneWidget);
    expect(find.textContaining('também em conversas futuras'), findsOneWidget);
    expect(find.textContaining('só para esta execução'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('o composer fica fechado enquanto o Hermes espera', (
    tester,
  ) async {
    await abrir(tester, comPedido());

    final campo = tester.widget<TextField>(find.byType(TextField).last);
    expect(campo.enabled, isFalse);
    expect(find.text('Aguardando sua decisão acima…'), findsOneWidget);
    // O botão vira cadeado: mostrar "parar" prometeria uma saída que ele não dá,
    // porque a saída explícita é recusar no card.
    expect(find.byIcon(Icons.stop_rounded), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);

    await fechar(tester);
  });

  testWidgets('sem pedido pendente nada de aprovação aparece', (tester) async {
    await abrir(tester, comPedido(null));

    expect(find.byKey(const ValueKey('approval-card')), findsNothing);
    final campo = tester.widget<TextField>(find.byType(TextField).last);
    expect(campo.enabled, isTrue);

    await fechar(tester);
  });

  testWidgets('nada é enviado ao servidor sem toque', (tester) async {
    final repo = FakeHermesRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWithValue(comPedido()),
          hermesRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
      ),
    );
    // Vários frames, e o card segue esperando.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(repo.aprovacoes, isEmpty, reason: 'nada é aprovado por omissão');
    expect(find.byKey(const ValueKey('approval-card')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('card revela para cima e bloqueia toques durante o movimento', (
    tester,
  ) async {
    ApprovalRequest? request;
    late StateSetter rebuild;
    var choices = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return ApprovalCardTransition(
                  request: request,
                  onChoice: (_) => choices++,
                );
              },
            ),
          ),
        ),
      ),
    );

    rebuild(() => request = _pedido);
    await tester.pump();
    final transition = find.byKey(const ValueKey('approval-card-transition'));
    final startHeight = tester.getSize(transition).height;
    await tester.tap(
      find.byKey(const ValueKey('approval-once')),
      warnIfMissed: false,
    );
    expect(choices, 0, reason: 'botão ainda está chegando sob o dedo');

    await tester.pump(const Duration(milliseconds: 180));
    final middleHeight = tester.getSize(transition).height;
    await tester.pumpAndSettle();
    final fullHeight = tester.getSize(transition).height;
    expect(middleHeight, greaterThan(startHeight));
    expect(fullHeight, greaterThan(middleHeight));

    await tester.tap(find.byKey(const ValueKey('approval-once')));
    expect(choices, 1, reason: 'card assentado aceita uma decisão');

    rebuild(() => request = null);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('approval-once')),
      warnIfMissed: false,
    );
    expect(choices, 1, reason: 'card em saída não aceita segundo toque');
    await tester.pump(const Duration(milliseconds: 90));
    expect(tester.getSize(transition).height, lessThan(fullHeight));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('approval-card')), findsNothing);
  });

  testWidgets('remover animações troca o card imediatamente', (tester) async {
    ApprovalRequest? request;
    late StateSetter rebuild;
    var choices = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return ApprovalCardTransition(
                  request: request,
                  onChoice: (_) => choices++,
                );
              },
            ),
          ),
        ),
      ),
    );

    rebuild(() => request = _pedido);
    await tester.pump();
    final switcher = tester.widget<AnimatedSwitcher>(
      find.byKey(const ValueKey('approval-card-transition')),
    );
    expect(switcher.duration, Duration.zero);
    await tester.tap(find.byKey(const ValueKey('approval-once')));
    expect(choices, 1);
  });

  testWidgets('primeira escolha desabilita todas e mostra progresso', (
    tester,
  ) async {
    var choices = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: ApprovalCard(
            request: _pedido,
            respondingTo: ApprovalChoice.once,
            onChoice: (_) => choices++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('approval-deny')),
      warnIfMissed: false,
    );
    expect(choices, 0);
  });
}
