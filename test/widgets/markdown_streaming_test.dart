import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/widgets/unicode_spinner.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';

/// Pedido do usuário em 2026-08-08, itens 3 e 4: o markdown tem de estar
/// desenhado **enquanto** a resposta chega, e a thread não pode ficar pesada
/// por causa disso. Fecha também o A35, que descrevia o defeito pelo outro
/// lado: a troca de árvore no fim do turno reorganizava o parágrafo enquanto
/// ele aparecia.
const _marca = ValueKey('streaming-brand');

Future<void> _montar(
  WidgetTester tester,
  String texto, {
  bool streaming = true,
  double? largura,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: largura,
            child: HermesMarkdown(texto, streaming: streaming),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

RenderParagraph _paragrafoCom(WidgetTester tester, String trecho) => tester
    .allRenderObjects
    .whereType<RenderParagraph>()
    .firstWhere((item) => item.text.toPlainText().contains(trecho));

/// Estilo efetivo de cada trecho de texto do parágrafo que contém [trecho].
/// O estilo herdado do span de cima entra por merge, senão a comparação leria
/// `null` onde o texto de fato tem tamanho e face.
Map<String, TextStyle> _estilosPorTexto(WidgetTester tester, String trecho) {
  final resultado = <String, TextStyle>{};
  void descer(InlineSpan span, TextStyle herdado) {
    if (span is! TextSpan) return;
    final atual = span.style == null ? herdado : herdado.merge(span.style);
    final texto = span.text;
    if (texto != null && texto.trim().isNotEmpty) {
      resultado[texto.replaceAll(RegExp(r'[.,]$'), '')] = atual;
    }
    for (final filho in span.children ?? const <InlineSpan>[]) {
      descer(filho, atual);
    }
  }

  descer(_paragrafoCom(tester, trecho).text, const TextStyle());
  return resultado;
}

void main() {
  testWidgets('o markdown já está formatado durante o streaming', (
    tester,
  ) async {
    await _montar(
      tester,
      '## Título em chegada\n\nCorpo com **negrito** ainda sendo escrito',
    );

    // Antes, o parcial era `RichText` cru: `##` e `**` apareciam como sujeira
    // até o turno acabar.
    expect(find.textContaining('##', findRichText: true), findsNothing);
    expect(find.textContaining('**', findRichText: true), findsNothing);

    TextStyle estiloDo(String paragrafo, String trecho) => _estilosPorTexto(
      tester,
      paragrafo,
    ).entries.firstWhere((entry) => entry.key.contains(trecho)).value;
    final titulo = estiloDo('Título em chegada', 'Título em chegada');
    final corpo = estiloDo('ainda sendo escrito', 'ainda sendo escrito');
    expect(
      titulo.fontSize,
      greaterThan(corpo.fontSize!),
      reason: 'título tem de sair maior que o corpo já durante a chegada',
    );
  });

  testWidgets('a cauda formata igual ao markdown já decidido', (tester) async {
    // A comparação certa não é contra um valor fixo: é contra o próprio
    // `MarkdownBody`, que desenha esta mesma frase assim que o turno conclui.
    // Se as duas divergirem, o texto muda de forma no instante em que a marca
    // some, que é exatamente o salto que o A35 descreve.
    const frase = 'Uma frase com **peso**, com *inclinação* e com `código`.';

    await _montar(tester, frase);
    final naCauda = _estilosPorTexto(tester, 'Uma frase com');

    await _montar(tester, frase, streaming: false);
    final noFinal = _estilosPorTexto(tester, 'Uma frase com');

    for (final palavra in ['peso', 'inclinação', 'código']) {
      expect(
        naCauda[palavra]?.fontFamily,
        noFinal[palavra]?.fontFamily,
        reason: '"$palavra" muda de face entre a cauda e o final',
      );
      expect(
        naCauda[palavra]?.fontSize,
        noFinal[palavra]?.fontSize,
        reason: '"$palavra" muda de tamanho entre a cauda e o final',
      );
    }
    // E as três faces são de fato diferentes entre si: sem isto o teste passaria
    // com tudo saindo no mesmo estilo dos dois lados.
    expect(
      {
        naCauda['peso']?.fontFamily,
        naCauda['inclinação']?.fontFamily,
        naCauda['código']?.fontFamily,
      }.length,
      3,
    );
  });

  testWidgets('concluir o turno não move o que já estava na tela', (
    tester,
  ) async {
    // O coração do A35: o texto já lido fica exatamente onde estava quando a
    // marca some. Antes, a árvore inteira era trocada e o parágrafo refluía
    // durante um fade de 650 ms.
    const resposta =
        'Primeiro parágrafo, já fechado.\n\nSegundo parágrafo, o último.';

    await _montar(tester, resposta);
    final durante = tester.getRect(
      find.textContaining('Primeiro parágrafo', findRichText: true),
    );
    final caudaDurante = tester.getRect(
      find.textContaining('Segundo parágrafo', findRichText: true),
    );

    await _montar(tester, resposta, streaming: false);
    final depois = tester.getRect(
      find.textContaining('Primeiro parágrafo', findRichText: true),
    );
    final caudaDepois = tester.getRect(
      find.textContaining('Segundo parágrafo', findRichText: true),
    );

    expect(depois, durante, reason: 'o bloco decidido não pode se mexer');
    expect(
      caudaDepois.topLeft,
      caudaDurante.topLeft,
      reason: 'a última linha também fica onde estava',
    );
    expect(find.byKey(_marca), findsNothing);
  });

  testWidgets('bloco decidido não é reconstruído quando a cauda cresce', (
    tester,
  ) async {
    // A prova de que o cache pega: o **mesmo objeto** de widget é devolvido, e
    // é isso que faz o `Element.updateChild` do Flutter pular a subárvore.
    const inicio = 'Parágrafo fechado que não muda mais.\n\nCauda';
    await _montar(tester, inicio);
    final antes = tester
        .widgetList<MarkdownBody>(find.byType(MarkdownBody))
        .first;

    await _montar(tester, '$inicio em construção, crescendo mais um pouco');
    final depois = tester
        .widgetList<MarkdownBody>(find.byType(MarkdownBody))
        .first;

    expect(identical(antes, depois), isTrue);
    expect(antes.data, 'Parágrafo fechado que não muda mais.');
  });

  testWidgets('a marca fica na linha quando a cauda é parágrafo', (
    tester,
  ) async {
    await _montar(tester, 'Uma frase curta');
    final texto = tester.getRect(
      find.textContaining('Uma frase curta', findRichText: true),
    );
    final marca = tester.getRect(find.byKey(_marca));
    expect(marca.left, greaterThan(texto.left));
    expect(marca.bottom, lessThanOrEqualTo(texto.bottom + 1));
  });

  testWidgets('a marca desce quando a cauda é lista, tabela ou código', (
    tester,
  ) async {
    // Numa lista ou numa tabela não existe "fim de linha" onde a marca caiba
    // sem desmontar o bloco, então ela vai abaixo, e não some.
    for (final cauda in <String>[
      '- primeiro item\n- segundo item',
      '| a | b |\n| --- | --- |\n| 1 | 2 |',
      '```dart\nvoid main() {',
    ]) {
      await _montar(tester, cauda);
      expect(find.byKey(_marca), findsOneWidget, reason: 'cauda: $cauda');
      expect(
        tester.widget<UnicodeSpinner>(find.byKey(_marca)).active,
        isTrue,
        reason: 'cauda: $cauda',
      );
    }
  });

  testWidgets(
    'item numerado longo mantém hanging indent em cada prefixo e no final',
    (tester) async {
      const prefixes = [
        '1. Primeiro passo com uma explicação suficientemente longa',
        '1. Primeiro passo com uma explicação suficientemente longa para quebrar em mais de uma linha.',
        '1. Primeiro passo com uma explicação suficientemente longa para quebrar em mais de uma linha.\nA continuação chega depois e ainda pertence ao mesmo item numerado',
        '1. Primeiro passo com uma explicação suficientemente longa para quebrar em mais de uma linha.\nA continuação chega depois e ainda pertence ao mesmo item numerado, sem abandonar o recuo.',
      ];

      double? contentLeft;
      for (final prefix in prefixes) {
        await _montar(tester, prefix, largura: 220);
        final content = _paragrafoCom(tester, 'Primeiro passo');
        final contentRect = tester.getRect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Primeiro passo'),
          ),
        );
        final markerRect = tester.getRect(
          find.byWidgetPredicate(
            (widget) => widget is RichText && widget.text.toPlainText() == '1.',
          ),
        );

        expect(content.size.height, greaterThan(50));
        expect(markerRect.right, lessThanOrEqualTo(contentRect.left));
        contentLeft ??= contentRect.left;
        expect(contentRect.left, closeTo(contentLeft, 0.01));
      }

      await _montar(tester, prefixes.last, streaming: false, largura: 220);
      final finalRect = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('Primeiro passo'),
        ),
      );
      expect(finalRect.left, closeTo(contentLeft!, 0.01));
      expect(
        _paragrafoCom(tester, 'Primeiro passo').text.toPlainText(),
        contains('A continuação chega depois'),
      );
    },
  );

  testWidgets(
    'código em construção já aparece como cartão, não como cerca crua',
    (tester) async {
      await _montar(tester, 'Veja:\n\n```dart\nvoid main() {\n  print(1);');
      expect(find.byKey(const ValueKey('markdown-code-card')), findsOneWidget);
      expect(find.textContaining('```', findRichText: true), findsNothing);
    },
  );

  testWidgets('turno ainda sem texto mostra só a marca', (tester) async {
    await _montar(tester, '');
    expect(find.byKey(_marca), findsOneWidget);
  });
}
