import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/tool_card_view.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

import '../support/fake_hermes_repository.dart';

AssistantMessage comFerramentas(int quantas, {ToolStatus? ultima}) =>
    AssistantMessage(
      id: 'a1',
      phase: ChatPhase.done,
      text: 'Pronto.',
      time: '09:30',
      tools: [
        for (var i = 0; i < quantas; i++)
          ToolCall(
            name: 'read_file',
            arg: 'arquivo$i.md',
            status: ToolStatus.done,
          ),
        if (ultima != null)
          ToolCall(name: 'terminal', arg: 'sleep 30', status: ultima),
      ],
    );

Future<void> abrir(
  WidgetTester tester,
  AssistantMessage message, {
  TimelineInteractionCallback? onTimelineInteraction,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AssistantBubble(
              message,
              onTimelineInteraction: onTimelineInteraction,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A bolha entra com animação; desmontar sem deixar o relógio parado evita o
/// "Timer is still pending" do próprio framework de teste.
Future<void> fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('card longo abre fechado, com a contagem do que falta', (
    tester,
  ) async {
    await abrir(tester, comFerramentas(22));

    expect(find.text('arquivo0.md'), findsOneWidget);
    expect(find.text('arquivo21.md'), findsNothing);
    expect(find.text('MAIS 16 FERRAMENTAS'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('o toque abre e fecha de volta', (tester) async {
    await abrir(tester, comFerramentas(22));

    final toggle = find.byKey(const ValueKey('tool-card-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('arquivo21.md'), findsOneWidget);
    expect(find.text('MOSTRAR MENOS'), findsOneWidget);

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('arquivo21.md'), findsNothing);
    expect(find.text('MAIS 16 FERRAMENTAS'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('mostrar mais cresce abaixo e reverte durante a transição', (
    tester,
  ) async {
    await abrir(tester, comFerramentas(22));

    final toggle = find.byKey(const ValueKey('tool-card-toggle'));
    final laterContent = find.text('Pronto.');
    await tester.ensureVisible(toggle);
    final toggleTop = tester.getTopLeft(toggle).dy;
    final laterTop = tester.getTopLeft(laterContent).dy;

    await tester.tap(toggle);
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.getTopLeft(toggle).dy,
        moreOrLessEquals(toggleTop, epsilon: 1),
      );
    }
    expect(tester.getTopLeft(laterContent).dy, greaterThan(laterTop));

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('arquivo21.md'), findsNothing);
    expect(
      tester.getTopLeft(toggle).dy,
      moreOrLessEquals(toggleTop, epsilon: 1),
    );

    await fechar(tester);
  });

  testWidgets('mostrar mais registra intenção antes de expandir', (
    tester,
  ) async {
    var interactions = 0;
    await abrir(
      tester,
      comFerramentas(22),
      onTimelineInteraction: () => interactions++,
    );

    final toggle = find.byKey(const ValueKey('tool-card-toggle'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(interactions, 1);
    expect(find.text('MOSTRAR MENOS'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('card curto não ganha controle nenhum', (tester) async {
    await abrir(tester, comFerramentas(4));

    expect(find.byKey(const ValueKey('tool-card-toggle')), findsNothing);
    expect(find.text('arquivo3.md'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('erro no fim de um card longo continua visível fechado', (
    tester,
  ) async {
    await abrir(tester, comFerramentas(20, ultima: ToolStatus.error));

    expect(find.text('sleep 30'), findsOneWidget);
    expect(find.text('arquivo19.md'), findsNothing);
    expect(find.byKey(const ValueKey('tool-card-toggle')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('ferramenta em execução continua visível fechada', (
    tester,
  ) async {
    await abrir(tester, comFerramentas(20, ultima: ToolStatus.running));

    expect(find.text('sleep 30'), findsOneWidget);
    expect(find.textContaining('EXEC'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('o limite visível é o mesmo do domínio', (tester) async {
    await abrir(tester, comFerramentas(22));

    for (var i = 0; i < toolCardCollapseLimit; i++) {
      expect(find.text('arquivo$i.md'), findsOneWidget);
    }
    expect(find.text('arquivo$toolCardCollapseLimit.md'), findsNothing);

    await fechar(tester);
  });
}
