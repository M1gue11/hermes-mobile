import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/theme/design_scale.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';
import 'package:hermes_mobile/features/chat/widgets/message_bubbles.dart';

/// A16/A26: o design e o app declaram os dois 16px, então o número nunca foi o
/// problema. O que difere é a **tela**: o mock do Claude Design é fixo em 390px
/// e o emulador tem 448px lógicos, então o mesmo 16 ocupa menos da tela aqui do
/// que lá. Quem converte é o [DesignTypography] da raiz; o código de tela
/// escreve o número do design cru.
const _prosa =
    'Um paragrafo de corpo com medida suficiente para revelar '
    'a diferenca de escala entre as duas larguras.';

/// Monta [child] numa tela de largura exata, com a tipografia do app instalada.
Future<void> montarEm(WidgetTester tester, double largura, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(largura, 2400);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      builder: (context, inner) =>
          DesignTypography(child: inner ?? const SizedBox.shrink()),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// Tamanho declarado no trecho.
///
/// Não serve olhar só `RichText.text.style`: o `Text.rich` do pacote de markdown
/// põe o estilo herdado na raiz e o estilo do parágrafo um nível abaixo, então a
/// raiz devolve o 14 do `DefaultTextStyle`. Aqui desce até o span mais interno
/// que contém o trecho e declara tamanho.
double? _tamanhoNoSpan(InlineSpan span, String trecho) {
  if (!span.toPlainText().contains(trecho)) return null;
  var encontrado = span.style?.fontSize;
  if (span is TextSpan) {
    for (final child in span.children ?? const <InlineSpan>[]) {
      final interno = _tamanhoNoSpan(child, trecho);
      if (interno != null) encontrado = interno;
    }
  }
  return encontrado;
}

/// O tamanho que a pessoa vê: o declarado depois do escalonador de texto.
double corpoDe(WidgetTester tester, String trecho) {
  for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
    final tamanho = _tamanhoNoSpan(rich.text, trecho);
    if (tamanho != null) return rich.textScaler.scale(tamanho);
  }
  fail('nenhum texto com "$trecho" e tamanho declarado');
}

void main() {
  testWidgets('na tela do mock o corpo é exatamente 16', (tester) async {
    await montarEm(tester, designCanvasWidth, const HermesMarkdown(_prosa));
    expect(corpoDe(tester, 'paragrafo de corpo'), closeTo(16, 0.001));
  });

  testWidgets('na tela do emulador o corpo cresce na proporção da tela', (tester) async {
    await montarEm(tester, 448, const HermesMarkdown(_prosa));
    // 448 / 390: o corpo passa a ocupar a mesma fatia da largura que no mock.
    expect(corpoDe(tester, 'paragrafo de corpo'), closeTo(16 * 448 / 390, 0.02));
  });

  testWidgets('o número escrito na folha é o do design, sem escala embutida', (tester) async {
    // Regressão do A26: por um tempo a escala foi aplicada **duas** vezes,
    // porque a folha de estilo multiplicava e o escalonador da raiz também.
    await montarEm(tester, 448, const HermesMarkdown(_prosa));
    final declarado = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((rich) => _tamanhoNoSpan(rich.text, 'paragrafo de corpo'))
        .whereType<double>()
        .toSet();
    expect(declarado, {16.0});
  });

  testWidgets('a hierarquia do A6 sobrevive à escala', (tester) async {
    await montarEm(
      tester,
      448,
      const HermesMarkdown('# Alfa\n\n## Beta\n\n### Gama\n\n$_prosa'),
    );

    final h1 = corpoDe(tester, 'Alfa');
    final h2 = corpoDe(tester, 'Beta');
    final h3 = corpoDe(tester, 'Gama');
    final corpo = corpoDe(tester, 'paragrafo de corpo');

    expect(h1, greaterThan(h2));
    expect(h2, greaterThan(h3));
    expect(h3, greaterThan(corpo));
    // As proporções do design continuam de pé: 24 / 20.5 / 17.6 sobre 16.
    expect(h1 / corpo, closeTo(24 / 16, 0.001));
    expect(h2 / corpo, closeTo(20.5 / 16, 0.001));
    expect(h3 / corpo, closeTo(17.6 / 16, 0.001));
  });

  testWidgets('o corpo não salta de tamanho quando o turno conclui', (tester) async {
    // Regressão: o texto em chegada é `RichText` cru, que **não** lê o
    // escalonador do [MediaQuery] sozinho, e a resposta pronta passa pelo
    // markdown, que lê. Sem passar o escalonador à mão, a última palavra mudava
    // de tamanho no instante em que a run termina.
    await montarEm(
      tester,
      448,
      const AssistantBubble(
        AssistantMessage(id: 'a', phase: ChatPhase.writing, text: _prosa),
      ),
    );
    final escrevendo = corpoDe(tester, 'paragrafo de corpo');

    await montarEm(
      tester,
      448,
      const AssistantBubble(
        AssistantMessage(id: 'a', phase: ChatPhase.done, text: _prosa),
      ),
    );
    final pronto = corpoDe(tester, 'paragrafo de corpo');

    expect(escrevendo, pronto);
  });

  testWidgets('pergunta e resposta têm o mesmo corpo', (tester) async {
    await montarEm(
      tester,
      448,
      const Column(
        children: [
          UserBubble(UserMessage(id: 'u', text: _prosa, time: '09:30')),
          AssistantBubble(
            AssistantMessage(id: 'a', phase: ChatPhase.done, text: _prosa),
          ),
        ],
      ),
    );

    final corpos = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((rich) {
          final tamanho = _tamanhoNoSpan(rich.text, 'paragrafo de corpo');
          return tamanho == null ? null : rich.textScaler.scale(tamanho);
        })
        .whereType<double>()
        .toSet();

    expect(
      corpos,
      hasLength(1),
      reason: 'a bolha do usuário não pode escalar por conta própria',
    );
  });
}
