import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/markdown_stream.dart';

/// Documentos de amostra. Cada um existe por um motivo, dito no nome: são os
/// casos em que dividir cedo demais desenharia errado.
const _corpus = <String, String>{
  'parágrafos simples': 'Primeiro parágrafo.\n\nSegundo parágrafo.\n\nTerceiro.',
  'título e corpo': '# Título\n\nCorpo do texto.\n\n## Outro\n\nMais corpo.',
  'lista frouxa': '- primeiro\n\n- segundo\n\n- terceiro\n\nParágrafo depois.',
  'lista com continuação recuada':
      '- primeiro\n\n  continuação do primeiro\n\n- segundo\n\nFim.',
  'lista numerada': '1. um\n2. dois\n\nTexto solto.\n\n1. novo um\n2. novo dois',
  'cerca de código':
      'Antes.\n\n```dart\nvoid main() {}\n```\n\nDepois.',
  'cerca colada no parágrafo': 'Antes.\n```sh\nls\n```\nDepois.',
  'duas cercas seguidas': '```a\num\n```\n```b\ndois\n```',
  'tabela': 'Antes.\n\n| a | b |\n| --- | --- |\n| 1 | 2 |\n\nDepois.',
  'citação': 'Antes.\n\n> citado\n> mais citado\n\nDepois.',
  'código indentado': 'Antes.\n\n    linha um\n\n    linha dois\n\nDepois.',
  'aninhado': '- item\n  - subitem\n\n  - outro subitem\n\nFora da lista.',
  'regra e fleurão': 'Antes.\n\n---\n\nDepois.',
};

void main() {
  group('estabilidade de prefixo', () {
    // O que já foi decidido num prefixo é o começo do que o texto completo
    // produz. É o que faz o cache valer a pena: bloco decidido não é reparsado
    // nem redesenhado enquanto o resto da resposta chega.
    //
    // A definição de referência de link está **fora** deste corpus de
    // propósito: ela é a exceção conhecida, coberta pelo seu próprio teste
    // abaixo.
    for (final entrada in _corpus.entries) {
      test('em "${entrada.key}", nenhum bloco decidido muda depois', () {
        final completo = splitMarkdownStream(entrada.value);
        for (var fim = 1; fim <= entrada.value.length; fim++) {
          final parcial = splitMarkdownStream(entrada.value.substring(0, fim));
          final decididos = parcial.where((bloco) => bloco.settled).toList();
          expect(
            decididos.length,
            lessThanOrEqualTo(completo.length),
            reason: 'prefixo de $fim decidiu mais blocos do que o texto todo',
          );
          for (var i = 0; i < decididos.length; i++) {
            expect(
              decididos[i].source,
              completo[i].source,
              reason:
                  'no prefixo de $fim caracteres, o bloco decidido $i não é o '
                  'bloco $i do texto completo',
            );
          }
        }
      });
    }
  });

  group('preservação do conteúdo', () {
    for (final entrada in _corpus.entries) {
      test('em "${entrada.key}", nada do texto se perde', () {
        final blocos = splitMarkdownStream(entrada.value);
        String semEspaco(String valor) =>
            valor.replaceAll(RegExp(r'\s+'), ' ').trim();
        expect(
          semEspaco(blocos.map((bloco) => bloco.source).join('\n')),
          semEspaco(entrada.value),
        );
      });
    }
  });

  test('o último bloco nunca está decidido: é onde a escrita continua', () {
    for (final entrada in _corpus.values) {
      final blocos = splitMarkdownStream(entrada);
      final ultimo = blocos.last;
      // A exceção é a cerca fechada: `\`\`\`` de fechamento decide o bloco, e
      // texto novo depois dela abre um bloco novo em vez de mudar este.
      if (ultimo is MarkdownFence && ultimo.closed) continue;
      expect(ultimo.settled, isFalse);
    }
  });

  test('lista frouxa fica inteira num bloco só', () {
    final blocos = splitMarkdownStream('- a\n\n- b\n\nDepois.');
    expect(blocos.length, 2);
    expect(blocos.first.source, '- a\n\n- b');
    expect(blocos.first.settled, isTrue);
    expect(blocos.last.source, 'Depois.');
  });

  test('parágrafo depois da lista fecha a lista', () {
    final blocos = splitMarkdownStream('- a\n- b\n\ntexto\n\n- c');
    expect(blocos.map((bloco) => bloco.source), ['- a\n- b', 'texto', '- c']);
  });

  test('cerca fechada vira bloco decidido com linguagem e corpo', () {
    final blocos = splitMarkdownStream('```dart\nvoid main() {}\n```\n\nfim');
    final cerca = blocos.first as MarkdownFence;
    expect(cerca.language, 'dart');
    expect(cerca.code, 'void main() {}\n');
    expect(cerca.closed, isTrue);
    expect(cerca.settled, isTrue);
  });

  test('cerca ainda aberta não está decidida, e já entrega o que tem', () {
    final blocos = splitMarkdownStream('```dart\nvoid main() {');
    final cerca = blocos.single as MarkdownFence;
    expect(cerca.closed, isFalse);
    expect(cerca.settled, isFalse);
    expect(cerca.code, 'void main() {');
  });

  test('cerca indentada pertence ao item de lista e não é arrancada', () {
    // Na coluna zero a cerca encerra a lista; recuada, ela é conteúdo do item.
    // Arrancá-la partiria a lista em duas metades com espaçamento diferente.
    final blocos = splitMarkdownStream('- item\n\n  ```dart\n  x\n  ```\n');
    expect(blocos.whereType<MarkdownFence>(), isEmpty);
  });

  test('definição de referência proíbe qualquer divisão', () {
    // A definição vale para o documento inteiro, inclusive para o link que
    // aparece antes dela.
    final blocos = splitMarkdownStream(
      'Veja o [manual].\n\nOutro.\n\n[manual]: https://exemplo.test',
    );
    expect(blocos.length, 1);
    expect(blocos.single.settled, isFalse);
  });

  test('a definição chegando no fim desmonta a divisão do prefixo', () {
    // A única quebra conhecida da estabilidade de prefixo, e por que ela é
    // aceitável: enquanto a definição não chegou, `Veja o [manual].` é um
    // parágrafo comum e desenha certo como tal. Quando ela chega, o documento
    // vira um bloco só e o link passa a existir. Como o cache é chaveado pela
    // fonte do bloco, a mudança de forma redesenha, em vez de mostrar o
    // parágrafo velho sem link.
    const completo =
        'Veja o [manual].\n\nOutro.\n\n[manual]: https://exemplo.test';
    final antes = splitMarkdownStream('Veja o [manual].\n\nOutro.');
    expect(antes.first.settled, isTrue, reason: 'sem definição, decide normal');

    final depois = splitMarkdownStream(completo);
    expect(depois.single.source, completo);
    expect(
      depois.single.source,
      isNot(antes.first.source),
      reason: 'a fonte muda, então a chave de cache muda e o bloco é redesenhado',
    );
  });

  test('texto vazio devolve um bloco só, indeciso', () {
    final blocos = splitMarkdownStream('');
    expect(blocos.single.source, '');
    expect(blocos.single.settled, isFalse);
  });

  test('cerca na coluna zero decide a prosa acima mesmo sem linha em branco', () {
    final blocos = splitMarkdownStream('Antes.\n```sh\nls\n```');
    expect(blocos.first.source, 'Antes.');
    expect(blocos.first.settled, isTrue);
  });
}
