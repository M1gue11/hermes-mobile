import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/theme/hermes_motion.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';

Future<void> montar(WidgetTester tester, String markdown) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(
        body: SingleChildScrollView(child: HermesMarkdown(markdown)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('callout renderiza título e markdown interno sem sintaxe crua', (
    tester,
  ) async {
    await montar(
      tester,
      '> [!warning] Título personalizado\n> Corpo com **negrito**.\n>\n> - item',
    );

    expect(find.text('Título personalizado'), findsOneWidget);
    expect(find.textContaining('[!warning]', findRichText: true), findsNothing);
    expect(
      find.textContaining('Corpo com', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('item'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('obsidian-callout-warning-Título personalizado'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('callout fechado abre e o aberto pode ser recolhido', (
    tester,
  ) async {
    await montar(
      tester,
      '> [!faq]- Fechado\n> segredo\n\n> [!example]+ Aberto\n> conteúdo',
    );

    expect(find.text('segredo'), findsNothing);
    expect(find.text('conteúdo'), findsOneWidget);

    await tester.tap(find.text('Fechado'));
    await tester.pumpAndSettle();
    expect(find.text('segredo'), findsOneWidget);

    await tester.tap(find.text('Aberto'));
    await tester.pumpAndSettle();
    expect(find.text('conteúdo'), findsNothing);
  });

  testWidgets('callout suporta aninhamento e tabela interna', (tester) async {
    await montar(
      tester,
      '> [!question] Externo\n> texto\n>\n> > [!idea] Interno\n> > dentro\n\n> [!abstract] Dados\n> | Chave | Valor |\n> |---|---:|\n> | A | 1 |',
    );

    expect(find.text('Externo'), findsOneWidget);
    expect(find.text('Interno'), findsOneWidget);
    expect(find.text('dentro'), findsOneWidget);
    expect(find.text('Dados'), findsOneWidget);
    expect(find.byType(Table), findsOneWidget);
    final table = tester.widget<Table>(find.byType(Table));
    expect(table.defaultColumnWidth, isA<IntrinsicColumnWidth>());
    expect(tester.getSize(find.byType(Table)).width, greaterThanOrEqualTo(144));
  });

  testWidgets('details começa fechado e preserva markdown ao abrir', (
    tester,
  ) async {
    await montar(
      tester,
      '<details>\n<summary>Bloco HTML expansível</summary>\n\nTexto com **negrito**.\n\n- item\n</details>',
    );

    expect(find.text('Bloco HTML expansível'), findsOneWidget);
    expect(find.textContaining('Texto com', findRichText: true), findsNothing);
    await tester.tap(find.text('Bloco HTML expansível'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Texto com', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('item'), findsOneWidget);
  });

  testWidgets('kbd, blockquote HTML e lista de definições têm UI nativa', (
    tester,
  ) async {
    await montar(
      tester,
      '<kbd>Ctrl</kbd> + <kbd>K</kbd>\n\n<blockquote>\nCitação HTML.\n</blockquote>\n\n<dl>\n<dt>Termo</dt>\n<dd>Descrição</dd>\n</dl>',
    );

    expect(find.text('Ctrl'), findsOneWidget);
    expect(find.text('K'), findsOneWidget);
    expect(
      find.textContaining('Citação HTML', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('markdown-definition-list')),
      findsOneWidget,
    );
    expect(find.text('Termo'), findsOneWidget);
    expect(find.text('Descrição'), findsOneWidget);
  });

  testWidgets('comentários seguem visíveis e atenuados como nos prints', (
    tester,
  ) async {
    await montar(
      tester,
      'Antes %%comentário inline%% depois.\n\n%%\ncomentário em bloco\n%%',
    );

    expect(find.textContaining('%%comentário inline%%'), findsOneWidget);
    expect(find.textContaining('comentário em bloco'), findsOneWidget);
    final tokens = HermesTokens.of(tester.element(find.byType(HermesMarkdown)));
    final comentario = tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere(
          (widget) => widget.data?.contains('comentário inline') ?? false,
        );
    expect(comentario.style!.color, tokens.dim);
  });

  testWidgets('expansíveis seguem os tokens e respeitam movimento reduzido', (
    tester,
  ) async {
    const markdown =
        '<details>\n<summary>Detalhes</summary>\n\nCorpo\n</details>\n\n'
        '> [!faq]- Pergunta\n> Resposta';

    await montar(tester, markdown);
    expect(find.byType(AnimatedRotation), findsNWidgets(2));
    expect(find.byType(AnimatedSize), findsNWidgets(2));
    expect(
      tester.widgetList<AnimatedRotation>(find.byType(AnimatedRotation)),
      everyElement(
        isA<AnimatedRotation>().having(
          (widget) => widget.duration,
          'duration',
          HermesMotion.estado,
        ),
      ),
    );
    expect(
      tester.widgetList<AnimatedSize>(find.byType(AnimatedSize)),
      everyElement(
        isA<AnimatedSize>().having(
          (widget) => widget.duration,
          'duration',
          HermesMotion.revelar,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(child: HermesMarkdown(markdown)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AnimatedRotation), findsNWidgets(2));
    expect(find.byType(AnimatedSize), findsNWidgets(2));
    expect(
      tester
          .widgetList<AnimatedRotation>(find.byType(AnimatedRotation))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
    expect(
      tester
          .widgetList<AnimatedSize>(find.byType(AnimatedSize))
          .every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
  });
}
