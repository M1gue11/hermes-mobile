import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/features/chat/chat_state.dart';

import '../support/fake_hermes_repository.dart';

/// Reproduz a forma da sessão real que exibiu o defeito A9: um turno só, com
/// muitas ferramentas e uma resposta longa em markdown.
final pesada = ChatState(
  sessionId: 'sessao-pesada',
  messages: [
    const UserMessage(
      id: 'u1',
      text:
          'Assistente, queria que voce avançasse na implementação do Hermes '
          'mobile flutter. Principalmente na UI do markdown.',
      time: '13:25',
    ),
    AssistantMessage(
      id: 'a1',
      phase: ChatPhase.done,
      model: 'gpt-5.6-terra',
      time: '13:32',
      activity: 'Atividade histórica registrada pelo gateway.',
      tools: [
        for (var i = 0; i < 22; i++)
          ToolCall(
            id: 'call_$i',
            name: i.isEven ? 'search_files' : 'read_file',
            arg: '{"limit":30,"path":"/home/operator/algum/caminho/$i"}',
            status: ToolStatus.done,
          ),
      ],
      text: '''
Avancei a implementação no worktree isolado:

- block quotes ganharam **superfície tonalizada, faixa âmbar, borda e sombra**;
- `h2` ganhou regra editorial e `hr` virou divisor ornamental;
- código inline ganhou contraste sutil, e os cards de código ficaram mais
  profundos, mantendo cópia, seleção e scroll horizontal;
- ampliei o teste de Markdown para cobrir quote, regra de título e divisor.

O diff passou em `git diff --check`.

```dart
void main() {
  runApp(const HermesApp());
}
```

Fiquei bloqueada na validação completa: para rodar Flutter via Docker eu
precisaria recriar uma pasta temporária, e o ambiente exigiu sua confirmação
explícita para esse comando.
''',
    ),
  ],
);

void main() {
  testWidgets('sonda: o extent de rolagem corresponde ao conteúdo pintado', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatControllerProvider.overrideWithValue(pesada),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        ],
        child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final listFinder = find.byType(ListView);
    final scroll = tester.widget<ListView>(listFinder).controller!;
    final viewport = tester.getRect(listFinder);

    // Na thread cronológica, a extensão máxima é o fim declarado pelo próprio
    // ScrollPosition.
    scroll.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();

    // O último widget da thread é o spinner de cauda. No fim real, a base dele
    // tem de estar dentro do viewport, não centenas de pixels acima.
    final tail = find.byKey(const ValueKey('conversation-tail-spinner'));
    expect(tail, findsOneWidget);
    final tailRect = tester.getRect(tail);
    final folga = viewport.bottom - tailRect.bottom;

    debugPrint(
      'SONDA A9  maxScrollExtent=${scroll.position.maxScrollExtent.toStringAsFixed(1)} '
      'viewport=${viewport.height.toStringAsFixed(1)} '
      'base_da_cauda=${tailRect.bottom.toStringAsFixed(1)} '
      'folga_abaixo_da_cauda=${folga.toStringAsFixed(1)}',
    );

    expect(
      folga,
      inInclusiveRange(0, 60),
      reason:
          'no fim real não pode sobrar vão pintado abaixo do último item; '
          'folga de $folga indica extensão de rolagem sem conteúdo',
    );

    await tester.pumpWidget(const SizedBox());
  });
}
