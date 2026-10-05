import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';
import 'package:hermes_mobile/features/settings/agent_persona.dart';

void main() {
  const persona = AgentPersona(name: 'Cláudia', gender: AgentGender.feminine);

  testWidgets('bolha identifica a resposta pelo nome configurado', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: AssistantBubble(
            AssistantMessage(
              id: 'a1',
              text: 'Olá',
              phase: ChatPhase.done,
              time: '10:30',
            ),
            persona: persona,
          ),
        ),
      ),
    );

    expect(find.text('CLÁUDIA'), findsOneWidget);
    expect(find.text('HERMES'), findsNothing);
  });

  testWidgets('streaming anuncia o nome configurado ao leitor de tela', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: HermesMarkdown('', streaming: true, persona: persona),
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Cláudia está respondendo',
      ),
      findsOneWidget,
    );
  });
}
