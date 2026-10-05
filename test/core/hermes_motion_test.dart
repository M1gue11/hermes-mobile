import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/hermes_motion.dart';

/// A41: o movimento do app tem de sair do mesmo vocabulário que o desenho, do
/// jeito que a cor já sai. Estes testes amarram cada constante à regra CSS de
/// `design/Hermes.dc.html` que a originou, então trocar um número sem trocar o
/// desenho quebra aqui.
final String _desenho = File('design/Hermes.dc.html').readAsStringSync();

/// `.34s` e `340ms` são a mesma coisa; o desenho escreve em segundos, com o
/// zero à esquerda omitido, que é como o CSS costuma vir.
String _emSegundos(Duration d) {
  final segundos = d.inMilliseconds / 1000;
  final texto = segundos.toStringAsFixed(3).replaceAll(RegExp(r'0+$'), '');
  return texto.startsWith('0.') ? texto.substring(1) : texto;
}

String _cubic(Cubic c) =>
    'cubic-bezier(${_num(c.a)},${_num(c.b)},${_num(c.c)},${_num(c.d)})';

String _num(double v) {
  final texto = v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '');
  final limpo = texto.endsWith('.') ? texto.substring(0, texto.length - 1) : texto;
  return limpo.startsWith('0.') ? limpo.substring(1) : limpo;
}

void main() {
  test('toda duração do vocabulário existe no desenho', () {
    // `toque` é o único caso em que o desenho usa dois valores vizinhos para o
    // mesmo papel (`.12s` no transform simples, `.13s` no com curva). O token
    // fica no maior dos dois, que é o do gesto com curva.
    expect(_desenho, contains('.13s'), reason: 'toque');
    for (final entrada in <String, Duration>{
      'estado': HermesMotion.estado,
      'superficie': HermesMotion.superficie,
      'revelar': HermesMotion.revelar,
      'entrada': HermesMotion.entrada,
      'tinta': HermesMotion.tinta,
      'brilho': HermesMotion.brilho,
    }.entries) {
      expect(
        _desenho,
        contains('${_emSegundos(entrada.value)}s'),
        reason:
            '${entrada.key} vale ${entrada.value.inMilliseconds}ms, e o desenho '
            'não declara ${_emSegundos(entrada.value)}s em lugar nenhum',
      );
    }
  });

  test('toda curva do vocabulário existe no desenho', () {
    for (final entrada in <String, Cubic>{
      'curvaToque': HermesMotion.curvaToque,
      'curvaChegada': HermesMotion.curvaChegada,
      'curvaPadrao': HermesMotion.curvaPadrao,
      'curvaSubida': HermesMotion.curvaSubida,
      'curvaTinta': HermesMotion.curvaTinta,
    }.entries) {
      expect(
        _desenho,
        contains(_cubic(entrada.value)),
        reason: '${entrada.key} não bate com nenhuma cubic-bezier do desenho',
      );
    }
  });

  test('saída é metade da entrada', () {
    // A proporção do A34: o card entra em 360 e recolhe em 180. Entrada é
    // aviso e merece ser percebida; saída é conclusão, e atrasá-la só faz
    // esperar.
    expect(
      HermesMotion.saidaDe(HermesMotion.revelar).inMilliseconds,
      HermesMotion.revelar.inMilliseconds ~/ 2,
    );
  });

  group('quem pede menos movimento recebe corte seco', () {
    Future<Duration> medir(
      WidgetTester tester, {
      bool disableAnimations = false,
      bool accessibleNavigation = false,
    }) async {
      late Duration lida;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            disableAnimations: disableAnimations,
            accessibleNavigation: accessibleNavigation,
          ),
          child: Builder(
            builder: (context) {
              lida = motionOf(context, HermesMotion.entrada);
              return const SizedBox();
            },
          ),
        ),
      );
      return lida;
    }

    testWidgets('sem pedido, a duração é a do desenho', (tester) async {
      expect(await medir(tester), HermesMotion.entrada);
    });

    testWidgets('disableAnimations zera', (tester) async {
      expect(await medir(tester, disableAnimations: true), Duration.zero);
    });

    testWidgets('leitor de tela também zera', (tester) async {
      // Com leitor de tela, a transição atrasa o anúncio do que mudou. A regra
      // veio do A34 e agora vale para o app inteiro.
      expect(await medir(tester, accessibleNavigation: true), Duration.zero);
    });
  });
}
