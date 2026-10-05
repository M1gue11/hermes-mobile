import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

import '../support/fake_hermes_repository.dart';

const _andaime =
    '[Your active task list was preserved across context compression]\n- rules';

Future<void> abrir(WidgetTester tester, Widget bubble) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(body: SingleChildScrollView(child: bubble)),
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
  testWidgets('andaime não vira bolha de fala', (tester) async {
    await abrir(
      tester,
      const UserBubble(
        UserMessage(id: 'u1', text: _andaime, time: '17:28', scaffolding: true),
      ),
    );

    expect(find.byKey(const ValueKey('andaime-do-gateway')), findsOneWidget);
    // Sem o rótulo "VOCÊ": atribuir isto à pessoa é justamente o defeito.
    expect(find.text('VOCÊ'), findsNothing);
    expect(find.textContaining('CONTEXTO DO GATEWAY'), findsOneWidget);
    expect(find.textContaining('LISTA DE TAREFAS'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('o texto exato fica a um toque, não escondido', (tester) async {
    await abrir(
      tester,
      const UserBubble(
        UserMessage(id: 'u1', text: _andaime, time: '17:28', scaffolding: true),
      ),
    );

    expect(find.textContaining('active task list'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('andaime-do-gateway')));
    await tester.pumpAndSettle();

    // Vai como veio: é o que o modelo leu.
    expect(find.textContaining('active task list'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('fala de gente continua com bolha, filete e rótulo', (
    tester,
  ) async {
    await abrir(
      tester,
      const UserBubble(
        UserMessage(id: 'u1', text: 'bom dia assistente!', time: '13:42'),
      ),
    );

    expect(find.byKey(const ValueKey('andaime-do-gateway')), findsNothing);
    expect(find.text('VOCÊ'), findsOneWidget);
    expect(find.text('bom dia assistente!'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('resumo assistant isolado não é atribuído ao Hermes', (
    tester,
  ) async {
    await abrir(
      tester,
      const AssistantBubble(
        AssistantMessage(
          id: 'a1',
          phase: ChatPhase.done,
          text:
              '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
              'Historical Task Snapshot: oculto',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('andaime-do-gateway')), findsOneWidget);
    expect(find.text('HERMES'), findsNothing);
    expect(find.textContaining('Historical Task Snapshot'), findsNothing);
    expect(find.byKey(const ValueKey('copiar-resposta')), findsNothing);

    await fechar(tester);
  });

  testWidgets('resumo assistant fundido mantém só a resposta como fala', (
    tester,
  ) async {
    await abrir(
      tester,
      const AssistantBubble(
        AssistantMessage(
          id: 'a1',
          phase: ChatPhase.done,
          text:
              '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
              'Historical Task Snapshot: oculto\n'
              '--- END OF CONTEXT SUMMARY ---\n'
              'Resposta legítima do Hermes.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('andaime-do-gateway')), findsOneWidget);
    expect(find.text('HERMES'), findsOneWidget);
    expect(find.textContaining('Resposta legítima'), findsOneWidget);
    expect(find.textContaining('Historical Task Snapshot'), findsNothing);
    expect(find.byKey(const ValueKey('copiar-resposta')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('prior context preserva a fala anterior do Hermes', (
    tester,
  ) async {
    await abrir(
      tester,
      const AssistantBubble(
        AssistantMessage(
          id: 'a1',
          phase: ChatPhase.done,
          text:
              '[PRIOR CONTEXT - for reference only; not a new message]\n'
              'Resposta anterior legítima.\n'
              '[END OF PRIOR CONTEXT - COMPACTION SUMMARY BELOW]\n'
              '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
              'Historical Task Snapshot\n'
              '--- END OF CONTEXT SUMMARY ---',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Resposta anterior legítima'), findsOneWidget);
    expect(find.textContaining('Historical Task Snapshot'), findsNothing);
    expect(find.byKey(const ValueKey('andaime-do-gateway')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('resumo user fundido preserva a fala real como Você', (
    tester,
  ) async {
    await abrir(
      tester,
      const UserBubble(
        UserMessage(
          id: 'u1',
          time: '17:28',
          scaffolding: true,
          text:
              '[CONTEXT SUMMARY]: contexto oculto\n'
              '--- END OF CONTEXT SUMMARY ---\n'
              'Minha pergunta legítima.',
        ),
      ),
    );

    expect(find.byKey(const ValueKey('andaime-do-gateway')), findsOneWidget);
    expect(find.text('VOCÊ'), findsOneWidget);
    expect(find.text('Minha pergunta legítima.'), findsOneWidget);
    expect(find.textContaining('contexto oculto'), findsNothing);

    await fechar(tester);
  });
}
