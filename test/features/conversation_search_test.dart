import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';

import '../support/fake_hermes_repository.dart';

Widget harness(ChatState state) => ProviderScope(
  overrides: [
    chatControllerProvider.overrideWithValue(state),
    hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
  ],
  child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
);

ChatState longThread() => ChatState(
  sessionId: 'sessao-busca',
  title: 'Conversa longa',
  messages: [
    for (var i = 0; i < 20; i++) ...[
      UserMessage(
        id: 'u$i',
        text: i == 1 ? 'Primeira agulha da conversa' : 'Pergunta número $i',
        time: '09:${i.toString().padLeft(2, '0')}',
      ),
      AssistantMessage(
        id: 'a$i',
        phase: ChatPhase.done,
        text: i == 18
            ? 'A segunda **agulha** está quase no fim.'
            : 'Resposta número $i com texto suficiente para ocupar espaço '
                  'e manter a lista virtualizada durante o teste.',
      ),
    ],
  ],
);

void main() {
  testWidgets('A25 abre com a limitação local explícita', (tester) async {
    await tester.pumpWidget(harness(longThread()));
    await tester.pumpAndSettle();

    final title = tester.getRect(find.text('Conversa longa'));
    final screen = tester.getRect(find.byType(Scaffold));
    expect(
      title.center.dx,
      moreOrLessEquals(screen.center.dx, epsilon: 1),
      reason: 'o segundo botão do A25 não pode tirar o título do centro',
    );

    await tester.tap(find.byKey(const ValueKey('conversation-search-toggle')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('conversation-search-bar')),
      findsOneWidget,
    );
    expect(find.text('SOMENTE MENSAGENS CARREGADAS'), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
    expect(
      tester.widget<ListView>(find.byType(ListView)).keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('busca ignora acento e mostra ausência só neste trecho', (
    tester,
  ) async {
    const state = ChatState(
      sessionId: 'sessao-curta',
      messages: [
        UserMessage(
          id: 'u-ancora',
          text: 'Validação da Âncora Consórcios',
          time: '09:30',
        ),
        AssistantMessage(
          id: 'a-resposta',
          phase: ChatPhase.done,
          text: 'Tudo certo.',
        ),
      ],
    );
    await tester.pumpWidget(harness(state));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conversation-search-toggle')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('conversation-search-field')),
      'ancora',
    );
    await tester.pumpAndSettle();

    expect(find.text('1 MENSAGEM NESTE TRECHO'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('search-highlight-u-ancora')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('conversation-search-field')),
      'inexistente',
    );
    await tester.pumpAndSettle();
    expect(find.text('NENHUMA NESTE TRECHO'), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('anterior e próximo alcançam itens fora da árvore virtualizada', (
    tester,
  ) async {
    await tester.pumpWidget(harness(longThread()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conversation-search-toggle')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('conversation-search-field')),
      'agulha',
    );
    await tester.pumpAndSettle();

    expect(find.text('2 MENSAGENS NESTE TRECHO'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-highlight-u1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('search-next')));
    await tester.pumpAndSettle();

    expect(find.text('2/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-highlight-a18')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('search-previous')));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    expect(find.byKey(const ValueKey('search-highlight-u1')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
