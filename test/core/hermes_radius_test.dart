import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/hermes_radius.dart';

/// A43: o app tinha doze arredondamentos e o desenho tem cinco. Este teste
/// amarra cada constante à regra CSS de `design/Hermes.dc.html` que a originou,
/// então inventar um número novo quebra aqui.
final String _desenho = File('design/Hermes.dc.html').readAsStringSync();

void main() {
  test('todo raio do vocabulário existe no desenho', () {
    for (final entrada in {
      'bloco': HermesRadius.bloco,
      'cartao': HermesRadius.cartao,
      'pastilha': HermesRadius.pastilha,
      'capsula': HermesRadius.capsula,
      'folha': HermesRadius.folha,
    }.entries) {
      final px = '${entrada.value.x.toInt()}px';
      expect(
        _desenho,
        contains(px),
        reason: '${entrada.key} vale $px, que o desenho não declara',
      );
    }
  });

  test('a escala é crescente e sem degraus repetidos', () {
    // Cinco papéis, cinco valores distintos, em ordem: quanto maior a
    // superfície, mais redondo o canto.
    final valores = [
      HermesRadius.bloco.x,
      HermesRadius.cartao.x,
      HermesRadius.pastilha.x,
      HermesRadius.capsula.x,
      HermesRadius.folha.x,
    ];
    expect(valores.toSet().length, valores.length);
    for (var i = 1; i < valores.length; i++) {
      expect(valores[i], greaterThan(valores[i - 1]));
    }
  });
}
