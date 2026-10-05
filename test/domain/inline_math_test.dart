import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/inline_math.dart';

String plano(String latex) => latexRuns(latex).map((r) => r.text).join();

void main() {
  group('latexRuns', () {
    test('o caso que apareceu no aparelho', () {
      // A resposta trazia `$O(\log n)$` e a tela mostrava a fórmula crua.
      expect(plano(r'O(\log n)'), 'O(log n)');
      final runs = latexRuns(r'O(\log n)');
      // `O` e `n` são variáveis; `log` e os parênteses, não. É essa distinção
      // que faz o trecho parecer fórmula e não frase.
      expect(runs.where((r) => r.variavel).map((r) => r.text), ['O', 'n']);
      expect(plano(r'\log'), 'log');
    });

    test('gregas, símbolos e setas', () {
      expect(plano(r'\alpha + \beta \leq \gamma'), 'α + β ≤ γ');
      expect(plano(r'a \times b \neq c'), 'a × b ≠ c');
      expect(plano(r'x \rightarrow \infty'), 'x → ∞');
      expect(plano(r'\Sigma \Omega'), 'Σ Ω');
    });

    test('grega minúscula é variável, símbolo de operação não', () {
      final runs = latexRuns(r'\alpha \times \beta');
      expect(runs.where((r) => r.variavel).map((r) => r.text), ['α', 'β']);
    });

    test('expoente e índice viram Unicode quando dá', () {
      expect(plano('x^2'), 'x²');
      expect(plano('x^{10}'), 'x¹⁰');
      expect(plano('a_1 + a_n'), 'a₁ + aₙ');
      expect(plano('e^{-x}'), 'e⁻ˣ');
    });

    test('expoente que não cabe em Unicode fica explícito', () {
      // Melhor `x^(abc)` legível do que um caractere trocado por outro.
      expect(plano('x^{qzw}'), 'x^(qzw)');
    });

    test('fração e raiz rasas', () {
      expect(plano(r'\frac{a}{b}'), 'a/b');
      expect(plano(r'\frac{x+1}{2}'), '(x+1)/2');
      expect(plano(r'\sqrt{2}'), '√2');
      expect(plano(r'\sqrt{x+1}'), '√(x+1)');
    });

    test('comando desconhecido sai sem a barra, não com ela', () {
      expect(plano(r'\oiint'), 'oiint');
    });

    test('delimitador elástico e espaçamento fino somem', () {
      expect(plano(r'\left( x \right)'), '( x )');
      // `\,` é espaço fino no LaTeX, e sai espaço fino de verdade (U+2009).
      expect(plano(r'a\,b'), 'a b');
    });
  });

  group('mathSpans', () {
    test('acha a fórmula inline e a de bloco', () {
      final texto = r'cresce como $O(\log n)$ no número de eventos.';
      final spans = mathSpans(texto);
      expect(spans, hasLength(1));
      expect(spans.single.latex, r'O(\log n)');
      expect(spans.single.display, isFalse);
      expect(texto.substring(spans.single.inicio, spans.single.fim), r'$O(\log n)$');

      final bloco = mathSpans(r'antes $$a = b$$ depois');
      expect(bloco, hasLength(1));
      expect(bloco.single.display, isTrue);
      expect(bloco.single.latex, 'a = b');
    });

    test('preço não vira fórmula', () {
      // O motivo de exigir marca de LaTeX: numa frase com dois preços, o par
      // de cifrões casaria e o meio viraria matemática.
      expect(mathSpans(r'de R$50 a R$80 no mês'), isEmpty);
      expect(mathSpans(r'custa $5 ou $10'), isEmpty);
      expect(mathSpans(r'total de R$ 1.240,00 e R$ 90,00'), isEmpty);
    });

    test('cifrão escapado não abre fórmula', () {
      expect(mathSpans(r'preço \$5 e \$8'), isEmpty);
    });

    test('inline não atravessa quebra de linha', () {
      expect(mathSpans('valor \$x\numa outra linha \$y'), isEmpty);
    });
  });
}
