import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

const _resposta = '## Título\n\nUm **negrito** e `run_stop`.';

/// Captura o que foi para a área de transferência sem tocar na plataforma.
class _Prancheta {
  String? valor;

  void instalar(WidgetTester tester) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          valor = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
  }
}

Future<void> abrir(WidgetTester tester, AssistantMessage message) async {
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

Future<void> fechar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  testWidgets('a resposta pronta oferece as duas cópias', (tester) async {
    await abrir(
      tester,
      const AssistantMessage(id: 'a', phase: ChatPhase.done, text: _resposta),
    );

    expect(find.byKey(const ValueKey('copiar-resposta')), findsOneWidget);
    expect(find.text('MARKDOWN'), findsOneWidget);
    expect(find.text('TEXTO'), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('markdown vai como o agente escreveu', (tester) async {
    final prancheta = _Prancheta()..instalar(tester);
    await abrir(
      tester,
      const AssistantMessage(id: 'a', phase: ChatPhase.done, text: _resposta),
    );

    await tester.tap(find.byKey(const ValueKey('copiar-markdown')));
    await tester.pump();

    expect(prancheta.valor, _resposta);

    await fechar(tester);
  });

  testWidgets('texto vai como está na tela', (tester) async {
    final prancheta = _Prancheta()..instalar(tester);
    await abrir(
      tester,
      const AssistantMessage(id: 'a', phase: ChatPhase.done, text: _resposta),
    );

    await tester.tap(find.byKey(const ValueKey('copiar-texto')));
    await tester.pump();

    expect(prancheta.valor, 'Título\n\nUm negrito e run_stop.');

    await fechar(tester);
  });

  testWidgets('compactação fundida copia somente a resposta visível', (
    tester,
  ) async {
    final prancheta = _Prancheta()..instalar(tester);
    await abrir(
      tester,
      const AssistantMessage(
        id: 'a',
        phase: ChatPhase.done,
        text:
            '[CONTEXT COMPACTION - REFERENCE ONLY]\n'
            'Historical Task Snapshot: oculto\n'
            '--- END OF CONTEXT SUMMARY ---\n'
            'Resposta **real**.',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('copiar-markdown')));
    await tester.pump();

    expect(prancheta.valor, 'Resposta **real**.');

    await fechar(tester);
  });

  testWidgets('turno em andamento não oferece cópia', (tester) async {
    // Copiar no meio da escrita levaria metade da resposta sem avisar.
    await abrir(
      tester,
      const AssistantMessage(id: 'a', phase: ChatPhase.writing, text: 'meio d'),
    );

    expect(find.byKey(const ValueKey('copiar-resposta')), findsNothing);

    await fechar(tester);
  });

  testWidgets('turno que falhou com texto parcial ainda copia', (tester) async {
    // O parcial é trabalho real do Hermes, como no A7.
    await abrir(
      tester,
      const AssistantMessage(
        id: 'a',
        phase: ChatPhase.failed,
        text: 'consegui escrever isto',
        error: 'Sem alcance ao Hermes',
      ),
    );

    expect(find.byKey(const ValueKey('copiar-resposta')), findsOneWidget);

    await fechar(tester);
  });

  testWidgets('turno sem texto não mostra a linha', (tester) async {
    await abrir(
      tester,
      const AssistantMessage(
        id: 'a',
        phase: ChatPhase.done,
        text: '',
        reasonTime: '2s',
      ),
    );

    expect(find.byKey(const ValueKey('copiar-resposta')), findsNothing);

    await fechar(tester);
  });
}
