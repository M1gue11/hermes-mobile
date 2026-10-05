import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';

/// Fixa a paridade com `design/Hermes.dc.html`, seção `/* markdown */`.
/// Cada expectativa cita a regra CSS de origem, para que uma mudança no design
/// seja rastreável até o teste que ela quebra.
const amostra = '''
Um parágrafo de corpo com medida suficiente para justificar de fato quando o
alinhamento estiver correto, e assim revelar a diferença.

## Título de segundo nível

Texto após o título.

---

| Coluna | Outra |
| --- | --- |
| a | b |
| c | d |

> Uma citação.
''';

Future<void> montar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      home: const Scaffold(
        body: SingleChildScrollView(child: HermesMarkdown(amostra)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('o corpo sai com bandeira à direita, não justificado', (
    tester,
  ) async {
    await montar(tester);

    // O design pede `.hmd p{text-align:justify;hyphens:auto}`, mas a
    // hifenização é metade da receita e o Flutter não hifeniza. Sem hífen, numa
    // medida de ~45 caracteres, justificar abria vãos enormes: no aparelho o
    // parágrafo "Link automático: https://..." virava três blocos separados por
    // espaços gigantes. Bandeira à direita é a escolha correta sem hífen.
    final paragrafo = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere(
          (rich) => rich.text.toPlainText().contains('justificar de fato'),
        );
    expect(paragrafo.textAlign, TextAlign.start);

    // O parágrafo com link é o caso que estourava: o pacote quebra a linha em
    // vários widgets e o `Wrap` distribuía os vãos entre eles.
    final wraps = tester.widgetList<Wrap>(find.byType(Wrap));
    expect(
      wraps.every((wrap) => wrap.alignment == WrapAlignment.start),
      isTrue,
      reason: 'nenhum bloco pode distribuir palavras pela largura da linha',
    );
  });

  testWidgets('a bala de lista é do corpo e o número é mono', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HermesMarkdown('- item\n\n1. passo'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // `.hmd ul li::marker` herda a serifa do corpo; `.hmd ol li::marker`
    // declara `font-family:var(--mono);font-size:.85em`.
    final bala = tester.widget<Text>(find.text('•'));
    final numero = tester.widget<Text>(find.text('1.'));
    final tokens = HermesTokens.of(tester.element(find.byType(HermesMarkdown)));
    expect(bala.style!.fontSize, 16);
    expect(numero.style!.fontSize, closeTo(13.6, 0.01));
    expect(bala.style!.fontFamily, isNot(numero.style!.fontFamily));
    expect(bala.style!.color, tokens.dim);
    expect(numero.style!.color, tokens.dim);
  });

  testWidgets('a caixa de tarefa é a do design, não o ícone do Material', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HermesMarkdown('- [x] feita\n- [ ] pendente'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // `.hmd input[type=checkbox]{border-radius:5px}` e, marcada, fundo âmbar.
    expect(find.byIcon(Icons.check_box), findsNothing);
    expect(find.byIcon(Icons.check_box_outline_blank), findsNothing);

    final caixas = tester.widgetList<Container>(find.byType(Container)).where((
      c,
    ) {
      final d = c.decoration;
      return d is BoxDecoration && d.borderRadius == BorderRadius.circular(5);
    }).toList();
    expect(caixas, hasLength(2));
    // A marcada é preenchida; a pendente só tem o contorno.
    final preenchidas = caixas.where(
      (c) => (c.decoration! as BoxDecoration).color != null,
    );
    expect(preenchidas, hasLength(1));
    final pendente = caixas.singleWhere(
      (c) => (c.decoration! as BoxDecoration).color == null,
    );
    final tokens = HermesTokens.of(tester.element(find.byType(HermesMarkdown)));
    expect(
      (pendente.decoration! as BoxDecoration).border!.top.color,
      tokens.dim,
    );
  });

  testWidgets('o h2 não inventa regra fora do conteúdo', (tester) async {
    await montar(tester);

    final titulo = find.text('Título de segundo nível');
    expect(titulo, findsOneWidget);

    final caixa = tester.widgetList<Container>(
      find.ancestor(of: titulo, matching: find.byType(Container)),
    );
    final comRegra = caixa.where((c) {
      final decoration = c.decoration;
      return decoration is BoxDecoration &&
          decoration.border?.bottom.width == 1;
    });
    expect(
      comRegra,
      isEmpty,
      reason: 'no Obsidian, só um hr explícito desenha um divisor',
    );
  });

  testWidgets('o hr vira divisor discreto como no Obsidian', (tester) async {
    await montar(tester);

    expect(find.text('❦'), findsNothing);
    final tokens = HermesTokens.of(tester.element(find.byType(HermesMarkdown)));
    final divisores = tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .where((box) => box.color == tokens.line);
    expect(divisores, hasLength(1));
  });

  testWidgets('oculta frontmatter e renderiza os dois realces', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: HermesMarkdown(
            '---\ntitle: Invisível\n---\n\n==âmbar== e <mark>também</mark>.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('title: Invisível'), findsNothing);
    expect(find.text('âmbar'), findsOneWidget);
    expect(find.text('também'), findsOneWidget);
  });

  testWidgets('h4, h5 e h6 preservam uma hierarquia decrescente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: HermesMarkdown('#### Quatro\n\n##### Cinco\n\n###### Seis'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    double? tamanhoDoSpan(InlineSpan span, String texto, [double? herdado]) {
      if (span is! TextSpan) return null;
      final tamanho = span.style?.fontSize ?? herdado;
      if (span.text == texto) return tamanho;
      for (final filho in span.children ?? const <InlineSpan>[]) {
        final encontrado = tamanhoDoSpan(filho, texto, tamanho);
        if (encontrado != null) return encontrado;
      }
      return null;
    }

    double tamanho(String texto) {
      final rich = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((widget) => widget.text.toPlainText() == texto);
      return tamanhoDoSpan(rich.text, texto)!;
    }

    expect(tamanho('Quatro'), greaterThan(tamanho('Cinco')));
    expect(tamanho('Cinco'), greaterThan(tamanho('Seis')));
  });

  testWidgets('a tabela usa filetes editoriais sem grade vertical', (
    tester,
  ) async {
    await montar(tester);

    final tabela = tester.widget<Table>(find.byType(Table));
    final borda = tabela.border!;
    expect(borda.verticalInside, BorderSide.none);
    expect(borda.horizontalInside.width, 1);
    expect(borda.left, BorderSide.none);
    expect(borda.right, BorderSide.none);
    expect(borda.top.width, 1.5);
    expect(borda.bottom.width, 1.5);
  });

  testWidgets('tabela curta ocupa toda a largura disponível', (tester) async {
    const availableWidth = 320.0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: ValueKey('markdown-table-viewport'),
              width: availableWidth,
              child: HermesMarkdown('''
| Indicador | Total |
| --- | ---: |
| Calorias | ~2.274 kcal |
| Proteínas | ~174 g |
'''),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final viewportWidth = tester
        .getSize(find.byKey(const ValueKey('markdown-table-viewport')))
        .width;
    final tableWidth = tester.getSize(find.byType(Table)).width;
    expect(tableWidth, closeTo(viewportWidth, 0.01));
  });

  testWidgets('as células mantêm respiro vertical e entre colunas', (
    tester,
  ) async {
    await montar(tester);

    final paddings = tester
        .widgetList<Padding>(
          find.descendant(
            of: find.byType(TableCell),
            matching: find.byType(Padding),
          ),
        )
        .map((widget) => widget.padding as EdgeInsets)
        .toList();

    expect(paddings, hasLength(6));
    for (final padding in paddings) {
      expect(padding.top, greaterThan(0));
      expect(padding.bottom, greaterThan(0));
      expect(padding.right, greaterThan(0));
      expect(padding.left, 0);
    }
  });

  testWidgets('estados estendidos ficam marcados sem virar texto concluído', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: HermesMarkdown(
            '- [ ] Pendente\n- [/] Fazendo\n- [x] Concluída\n- [-] Cancelada\n- [>] Adiada\n- [!] Importante',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final caixas = tester.widgetList<Container>(find.byType(Container)).where((
      container,
    ) {
      final decoration = container.decoration;
      return decoration is BoxDecoration &&
          decoration.borderRadius == BorderRadius.circular(5);
    }).toList();
    expect(caixas, hasLength(6));
    expect(
      caixas.where(
        (container) => (container.decoration! as BoxDecoration).color != null,
      ),
      hasLength(5),
    );
    expect(find.textContaining('[/]'), findsNothing);
    expect(find.textContaining('[-]'), findsNothing);
    expect(find.textContaining('[>]'), findsNothing);
    expect(find.textContaining('[!]'), findsNothing);
  });

  testWidgets('o bloco de código não tem borda externa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HermesMarkdown('```dart\nvoid main() {}\n```'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // `.hmd pre{border:none;border-radius:11px}`. A superfície mora na
    // `CodeSurface` desde o A24, que a compartilha com o conteúdo do anexo.
    final superficie = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('markdown-code-card')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = superficie.decoration as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.borderRadius, BorderRadius.circular(11));
  });

  testWidgets('fórmula inline sai renderizada, não crua', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HermesMarkdown(
              r'O overhead cresce como $O(\log n)$ no número de eventos.',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // O mock renderiza com KaTeX (`renderMathInElement`); aqui a fórmula vira
    // texto Unicode na fonte do corpo. O que não pode é aparecer o LaTeX cru,
    // que foi o que apareceu no aparelho.
    final texto = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((rich) => rich.text.toPlainText())
        .join();
    expect(texto, contains('O(log n)'));
    expect(texto, isNot(contains(r'\log')));
    expect(texto, isNot(contains(r'$')));
  });

  testWidgets('cifrão de preço continua cifrão', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: HermesMarkdown(r'de R$50 a R$80 no mês'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final texto = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((rich) => rich.text.toPlainText())
        .join();
    expect(texto, contains(r'R$50'));
    expect(texto, contains(r'R$80'));
  });
}
