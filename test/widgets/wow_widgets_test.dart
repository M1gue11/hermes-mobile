import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/widgets/paper_texture.dart';
import 'package:hermes_mobile/core/widgets/unicode_spinner.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';

void main() {
  group('UnicodeSpinner / marca braille', () {
    test('18 spinners, helix presente, frames não-vazios de braille', () {
      expect(kUnicodeSpinners.length, 18);
      expect(kUnicodeSpinners.containsKey('helix'), isTrue);
      for (final def in kUnicodeSpinners.values) {
        expect(def.frames, isNotEmpty);
        for (final frame in def.frames) {
          expect(frame, isNotEmpty);
          // Todo caractere está no bloco Braille Patterns (U+2800..U+28FF).
          for (final code in frame.runes) {
            expect(code, inInclusiveRange(0x2800, 0x28FF));
          }
        }
      }
    });

    testWidgets('anima sem exceção e desmonta limpo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: UnicodeSpinner(name: 'helix', size: 24)),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 90));
      await tester.pump(const Duration(milliseconds: 90));
      expect(find.byType(UnicodeSpinner), findsOneWidget);
      // desmonta p/ cancelar o timer (evita "pending timer")
      await tester.pumpWidget(const SizedBox());
    });

    for (final name in ['braillewave', 'dna']) {
      testWidgets('$name mede o desenho inteiro e o centraliza', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: UnicodeSpinner(name: name, size: 22, active: false)),
            ),
          ),
        );

        final spinner = find.byType(UnicodeSpinner);
        final glyphs = find.descendant(of: spinner, matching: find.byType(Text));
        expect(tester.getSize(glyphs).width, greaterThan(22));
        expect(tester.getCenter(glyphs).dx, closeTo(tester.getCenter(spinner).dx, 0.01));
      });
    }
  });

  testWidgets('PaperTexture (fundo sólido) pinta sem crashar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SizedBox(
            width: 300,
            height: 500,
            child: PaperTexture(grain: 0.55),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PaperTexture), findsOneWidget);
  });

  testWidgets('assistant concluído vazio não renderiza metadados nem spinner', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(),
      home: const Scaffold(body: AssistantBubble(
        AssistantMessage(id: 'empty', phase: ChatPhase.done),
      )),
    ));
    expect(find.text('HERMES'), findsNothing);
    expect(find.byType(UnicodeSpinner), findsNothing);
  });

  testWidgets('HermesMarkdown renderiza markdown rico sem crashar', (
    tester,
  ) async {
    const sample = '''
## Título

Um parágrafo com **negrito**, *itálico* e `código inline`.

```dart
final x = 1; // comentário
```

> uma citação

| A | B |
| - | - |
| 1 | 2 |

- [x] feito
- [ ] pendente
''';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(child: HermesMarkdown(sample)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HermesMarkdown), findsOneWidget);
    expect(find.textContaining('parágrafo'), findsOneWidget);
    expect(find.byKey(const ValueKey('markdown-code-card')), findsOneWidget);
    expect(find.byTooltip('Copiar código'), findsOneWidget);
  });
}
