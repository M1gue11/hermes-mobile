import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
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
  testWidgets('wikilinks usam o rótulo sem expor os colchetes', (tester) async {
    await montar(
      tester,
      '[[Nota inexistente]] · [[Nota|Texto de exibição]] · [[#Tabela]]',
    );

    expect(find.textContaining('[[', findRichText: true), findsNothing);
    expect(
      find.textContaining('Nota inexistente', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Texto de exibição', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Tabela', findRichText: true), findsOneWidget);
  });

  testWidgets('tags viram chips e embeds locais têm fallback legível', (
    tester,
  ) async {
    await montar(
      tester,
      '#renderer #teste/mobile\n\n![[imagem-inexistente.png|300]]',
    );

    expect(find.text('#renderer'), findsOneWidget);
    expect(find.text('#teste/mobile'), findsOneWidget);
    expect(
      find.text('Imagem local não encontrada: imagem-inexistente.png|300'),
      findsOneWidget,
    );
    expect(find.textContaining('![[', findRichText: true), findsNothing);
  });

  testWidgets('link pede confirmação e mostra o destino inteiro', (
    tester,
  ) async {
    await montar(
      tester,
      'Veja o [site do Hermes](https://exemplo.invalido/pagina?x=1).',
    );

    await tester.tapOnText(find.textRange.ofSubstring('site do Hermes'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir fora do Hermes?'), findsOneWidget);
    // O destino aparece por extenso: quem decide sair do app é a pessoa.
    expect(find.text('https://exemplo.invalido/pagina?x=1'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir fora do Hermes?'), findsNothing);
  });

  testWidgets('esquema não suportado não abre diálogo', (tester) async {
    await montar(tester, 'Um [link estranho](javascript:alert(1)) aqui.');

    await tester.tapOnText(find.textRange.ofSubstring('link estranho'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir fora do Hermes?'), findsNothing);
    expect(find.textContaining('Link não suportado'), findsOneWidget);
  });

  testWidgets('imagem que falha diz que falhou, com o texto alternativo', (
    tester,
  ) async {
    await montar(
      tester,
      '![diagrama do fluxo](https://exemplo.invalido/imagem.png)',
    );
    // Image.network falha no ambiente de teste, que é exatamente o caminho a
    // cobrir: a resposta não pode ficar com um buraco silencioso.
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Imagem indisponível'), findsOneWidget);
    expect(find.textContaining('diagrama do fluxo'), findsOneWidget);
    final aviso = tester
        .widgetList<Text>(find.byType(Text))
        .firstWhere(
          (widget) => widget.data?.contains('Imagem indisponível') ?? false,
        );
    final tokens = HermesTokens.of(tester.element(find.byType(HermesMarkdown)));
    expect(aviso.style!.color, tokens.dim);
  });

  testWidgets('tabela larga rola na horizontal em vez de espremer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 280,
              child: HermesMarkdown('''
| Coluna A | Coluna B | Coluna C |
| --- | --- | --- |
| identificador_sem_pontos_de_quebra_A | identificador_sem_pontos_de_quebra_B | identificador_sem_pontos_de_quebra_C |
'''),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // `.hmd table{overflow-x:auto}`: a tabela vive dentro de um scroll próprio.
    final scroll = find.ancestor(
      of: find.byType(Table),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scroll, findsWidgets);
    expect(
      tester
          .widgetList<SingleChildScrollView>(scroll)
          .any((view) => view.scrollDirection == Axis.horizontal),
      isTrue,
    );
    final horizontalView = tester
        .widgetList<SingleChildScrollView>(scroll)
        .firstWhere((view) => view.scrollDirection == Axis.horizontal);
    final scrollable = find.descendant(
      of: find.byWidget(horizontalView),
      matching: find.byType(Scrollable),
    );
    final state = tester.state<ScrollableState>(scrollable);
    expect(state.position.maxScrollExtent, greaterThan(0));
  });
}
