import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';

/// A15: o bloco de código do design colore por classe hljs
/// (`design/Hermes.dc.html`, seção `/* hljs */`). O card do app interceptava o
/// fence antes do `MarkdownBody`, então o realce configurado lá nunca rodava e o
/// bloco saía monocromático. Estes testes fixam a atribuição de cor por token.
const _amostra = '''
```dart
// conta os itens
class Balde {
  final int total = 42;
  String rotulo() => "cheio";
}
```
''';

late HermesTokens tokens;

Future<List<TextSpan>> spansDoCodigo(
  WidgetTester tester,
  String markdown,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      home: Builder(
        builder: (context) {
          tokens = HermesTokens.of(context);
          return Scaffold(
            body: SingleChildScrollView(child: HermesMarkdown(markdown)),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  // O código é selecionável pelo `SelectionArea` que envolve todo o
  // [HermesMarkdown], e não por um `SelectableText` próprio: aquele montava um
  // `EditableText` inteiro por bloco (medido: 84 ms no quadro em que a cerca de
  // código abre durante o streaming) e ainda se recusava a participar da
  // seleção da área, quebrando o arrasto que atravessa texto e código.
  expect(find.byKey(const ValueKey('markdown-code-card')), findsOneWidget);
  final paragrafo = tester.allRenderObjects
      .whereType<RenderParagraph>()
      .firstWhere((item) => item.text.toPlainText().contains('class'));
  final folhas = <TextSpan>[];
  void descer(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.text != null) folhas.add(span);
    for (final child in span.children ?? const <InlineSpan>[]) {
      descer(child);
    }
  }

  descer(paragrafo.text);
  return folhas;
}

TextSpan spanCom(List<TextSpan> spans, String texto) =>
    spans.firstWhere((span) => span.text == texto);

void main() {
  testWidgets('o bloco de código é colorido, não monocromático', (
    tester,
  ) async {
    final spans = await spansDoCodigo(tester, _amostra);
    final cores = spans.map((span) => span.style?.color).toSet();
    expect(
      cores.length,
      greaterThan(1),
      reason:
          'um bloco com comentário, palavra-chave, número e string não pode '
          'sair todo na mesma cor',
    );
  });

  testWidgets('cada token recebe a cor da tabela hljs do design', (
    tester,
  ) async {
    final spans = await spansDoCodigo(tester, _amostra);

    // Comentários continuam atenuados, mas legíveis em texto pequeno.
    final comentario = spanCom(spans, '// conta os itens');
    expect(comentario.style!.color, tokens.dim);
    expect(comentario.style!.fontStyle, FontStyle.italic);

    // `.hljs-keyword,.hljs-literal{color:var(--cKey)}`
    expect(spanCom(spans, 'class').style!.color, tokens.cKey);
    expect(spanCom(spans, 'final').style!.color, tokens.cKey);

    // `.hljs-number{color:var(--cNum)}`
    expect(spanCom(spans, '42').style!.color, tokens.cNum);

    // `.hljs-string{color:var(--cStr)}`
    expect(spanCom(spans, '"cheio"').style!.color, tokens.cStr);

    // `.hljs-type,.hljs-title.class_{color:var(--cType)}`
    expect(spanCom(spans, 'Balde').style!.color, tokens.cType);
    expect(spanCom(spans, 'String').style!.color, tokens.cType);

    // `.hljs-title.function_{color:var(--cFn)}`
    expect(spanCom(spans, 'rotulo').style!.color, tokens.cFn);

    // `.hljs-property,.hljs-variable{color:var(--ink)}`
    expect(spanCom(spans, 'total').style!.color, tokens.ink);
  });

  testWidgets('o código usa a entrelinha do design', (tester) async {
    final spans = await spansDoCodigo(tester, _amostra);
    // `.hmd pre{line-height:1.62}`
    expect(spans.first.style!.height, 1.62);
  });

  testWidgets('a sombra do topo tem altura fixa, não fração da caixa', (
    tester,
  ) async {
    // Regressão reportada pelo usuário: o degradê que simula
    // `inset 0 1px 5px rgba(0,0,0,.42)` parava em 5.5% da **altura**, então num
    // bloco alto virava uma faixa preta grossa. O `5px` do design é 5px.
    Future<Rect> sombraDe(String codigo) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HermesMarkdown('```dart\n$codigo\n```'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getRect(
        find.byKey(const ValueKey('markdown-code-inset-shadow')),
      );
    }

    final curta = await sombraDe('var a = 1;');
    final longa = await sombraDe(List.filled(30, 'var a = 1;').join('\n'));

    expect(
      curta.height,
      longa.height,
      reason: 'a sombra não pode crescer com o bloco',
    );
    expect(longa.height, lessThan(12), reason: 'é sombra, não faixa');
  });

  testWidgets('sem faixa, com linguagem discreta e botão de copiar', (
    tester,
  ) async {
    await spansDoCodigo(tester, _amostra);

    expect(find.text('DART'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('markdown-code-language')),
      findsOneWidget,
    );
    final linguagem = tester.widget<Text>(
      find.byKey(const ValueKey('markdown-code-language')),
    );
    expect(linguagem.style!.color, tokens.dim);
    expect(find.byTooltip('Copiar código'), findsOneWidget);

    // O botão flutua no canto superior direito do bloco, não numa barra própria
    // acima dele.
    final card = tester.getRect(
      find.byKey(const ValueKey('markdown-code-card')),
    );
    final botao = tester.getRect(find.byTooltip('Copiar código'));
    expect(botao.top, greaterThanOrEqualTo(card.top));
    expect(botao.right, lessThanOrEqualTo(card.right));
    expect(botao.left, greaterThan(card.center.dx));
  });

  testWidgets('fórmula de bloco é centralizada e não expõe delimitadores', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: HermesMarkdown(
            r'$$'
            '\n'
            r'\int_{0}^{1} x^2\,dx = \frac{1}{3}'
            '\n'
            r'$$',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('markdown-display-math')), findsOneWidget);
    expect(find.textContaining(r'$$', findRichText: true), findsNothing);
    expect(find.textContaining('∫', findRichText: true), findsOneWidget);
  });

  testWidgets('renderiza flowchart e sequência Mermaid nativamente', (
    tester,
  ) async {
    const markdown = '''
```mermaid
flowchart TD
  A[Mensagem] --> B{Renderer suporta?}
  B -->|Sim| C[Renderiza bonito]
  B -->|Não| D[Exibe código]
```

```mermaid
sequenceDiagram
  participant M as Pessoa
  participant H as Hermes Mobile
  M->>H: Abrir nota
  H-->>M: Resultado visual
```
''';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SingleChildScrollView(child: HermesMarkdown(markdown)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mermaid-flowchart')), findsOneWidget);
    expect(find.byKey(const ValueKey('mermaid-sequence')), findsOneWidget);
    expect(find.text('Renderer suporta?'), findsOneWidget);
    expect(find.text('Abrir nota'), findsOneWidget);
    expect(
      find.textContaining('flowchart TD', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('Mermaid preserva palavra curta e copia o código-fonte', (
    tester,
  ) async {
    const source = '''flowchart TD
  A[Ideia] --> B{Validar}
  B -->|Aprovada| C[Implementar]
  B -->|Ajustar| D[Refinar]''';
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
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

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: SizedBox(
            width: 340,
            child: HermesMarkdown('```mermaid\n$source\n```'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final implementar = tester.widget<Text>(find.text('Implementar'));
    expect(implementar.maxLines, 1);
    expect(implementar.softWrap, isFalse);
    expect(
      find.ancestor(
        of: find.text('Implementar'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('mermaid-copy-code')));
    await tester.pump();

    expect(copied, source);
    expect(find.text('Código copiado'), findsOneWidget);
  });

  testWidgets('renderiza Mermaid da fixture completa sem fallback de código', (
    tester,
  ) async {
    final markdown = await rootBundle.loadString(
      'assets/dev/obsidian_markdown_renderer_showcase.md',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(child: HermesMarkdown(markdown)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('mermaid-flowchart')), findsOneWidget);
    expect(find.byKey(const ValueKey('mermaid-sequence')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('markdown-code-card')),
      findsNWidgets(4),
      reason: 'fences no documento completo também usam o fundo rebaixado',
    );
    expect(
      find.textContaining('flowchart TD', findRichText: true),
      findsNothing,
    );
  });
}
