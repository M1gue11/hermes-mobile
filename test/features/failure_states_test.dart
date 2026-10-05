import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/widgets/failure_state.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

import '../support/fake_hermes_repository.dart';

Future<void> abrir(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [hermesRepositoryProvider.overrideWithValue(FakeHermesRepository())],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pump();
}

Future<void> fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('a tela de falha mostra causa, ação e referência', (tester) async {
    var tentou = 0;
    await abrir(
      tester,
      FailureState(
        failure: const HermesFailure(
          HermesFailureKind.gatewayIndisponivel,
          statusCode: 503,
          code: 'gateway_unavailable',
        ),
        keyPrefix: 'lista',
        onRetry: () => tentou++,
      ),
    );

    expect(find.byKey(const ValueKey('lista-falha-titulo')), findsOneWidget);
    expect(find.byKey(const ValueKey('lista-falha-dica')), findsOneWidget);
    expect(find.text('HTTP 503 · gateway_unavailable'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lista-falha-retry')));
    expect(tentou, 1);

    await fechar(tester);
  });

  testWidgets('não oferece retry quando tentar de novo não resolve', (tester) async {
    await abrir(
      tester,
      FailureState(
        failure: const HermesFailure(HermesFailureKind.naoAutenticado, statusCode: 401),
        keyPrefix: 'lista',
        onRetry: () {},
      ),
    );

    // Sem chave nova, o próximo toque falharia igual: o botão seria promessa
    // falsa, então não existe.
    expect(find.byKey(const ValueKey('lista-falha-retry')), findsNothing);
    expect(find.byKey(const ValueKey('lista-falha-dica')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('nenhuma tela de falha imprime toString de exceção', (tester) async {
    await abrir(
      tester,
      FailureState(
        failure: hermesFailureFrom(StateError('Bad state: coisa interna')),
        keyPrefix: 'lista',
      ),
    );

    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('coisa interna'), findsNothing);
    expect(find.textContaining('DioException'), findsNothing);

    await fechar(tester);
  });

  testWidgets('turno que falhou preserva o texto parcial', (tester) async {
    // O parcial é trabalho real do Hermes: apagá-lo esconderia o que já foi
    // dito antes da queda.
    await abrir(
      tester,
      const AssistantBubble(AssistantMessage(
        id: 'a1',
        phase: ChatPhase.failed,
        text: 'Comecei a responder e',
        error: 'Sem alcance ao Hermes. Confira a tailnet.',
        time: '09:30',
      )),
    );

    expect(find.byKey(const ValueKey('turno-falhou')), findsOneWidget);
    expect(find.textContaining('Comecei a responder', findRichText: true), findsOneWidget);
    expect(find.textContaining('Sem alcance ao Hermes'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('turno que falhou sem mensagem ainda diz alguma coisa', (tester) async {
    await abrir(
      tester,
      const AssistantBubble(AssistantMessage(
        id: 'a1',
        phase: ChatPhase.failed,
        time: '09:30',
      )),
    );

    expect(find.byKey(const ValueKey('turno-falhou')), findsOneWidget);
    expect(
      find.text(const HermesFailure(HermesFailureKind.respostaInesperada).title),
      findsOneWidget,
    );

    await fechar(tester);
  });
}
