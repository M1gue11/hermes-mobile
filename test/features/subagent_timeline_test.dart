import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

Future<void> _pump(WidgetTester tester, AssistantMessage message) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(
        body: SingleChildScrollView(child: AssistantBubble(message)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('B9: agentes delegados aparecem na timeline, fora da fala', (
    tester,
  ) async {
    const message = AssistantMessage(
      id: 'a1',
      phase: ChatPhase.done,
      activityItems: [
        TurnActivity.subagent(
          id: 's1',
          run: SubagentRun(
            key: 'a',
            goal: 'Ler os logs do gateway',
            taskCount: 2,
            phase: SubagentPhase.completed,
            summary: 'Nenhum erro nas últimas 24 h.',
            duration: Duration(milliseconds: 12500),
          ),
        ),
        TurnActivity.subagent(
          id: 's2',
          run: SubagentRun(
            key: 'b',
            goal: 'Conferir o disco',
            taskIndex: 1,
            taskCount: 2,
            phase: SubagentPhase.failed,
            lastNote: 'df -h',
          ),
        ),
      ],
      text: 'Os dois agentes terminaram.',
    );

    await _pump(tester, message);

    expect(find.byKey(const ValueKey('turn-subagent-s1')), findsOneWidget);
    expect(find.text('SUBAGENTE 1/2 · CONCLUÍDO · 12.5S'), findsOneWidget);
    expect(find.text('Ler os logs do gateway'), findsOneWidget);
    expect(find.text('Nenhum erro nas últimas 24 h.'), findsOneWidget);
    expect(find.text('SUBAGENTE 2/2 · FALHOU'), findsOneWidget);
    // Agente encerrado sem resumo não mostra a nota de quando rodava.
    expect(find.text('df -h'), findsNothing);
    expect(
      find.bySemanticsLabel(
        'Subagente 1/2, concluído · 12.5s: Ler os logs do gateway',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('agente rodando mostra o último sinal de vida', (tester) async {
    const message = AssistantMessage(
      id: 'a1',
      phase: ChatPhase.reasoning,
      activityItems: [
        TurnActivity.subagent(
          id: 's1',
          run: SubagentRun(
            key: 'a',
            goal: 'Rodar os testes',
            phase: SubagentPhase.running,
            toolCalls: 3,
            lastNote: 'terminal · flutter test',
          ),
        ),
      ],
    );

    await _pump(tester, message);

    expect(find.text('SUBAGENTE · RODANDO · 3 FERRAMENTAS'), findsOneWidget);
    expect(find.text('terminal · flutter test'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
