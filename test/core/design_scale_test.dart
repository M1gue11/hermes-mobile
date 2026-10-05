import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/design_scale.dart';

void main() {
  group('designScale', () {
    test('a referência é a moldura do mock', () {
      // `design/Hermes.dc.html` desenha o telefone com `width:390px`, e é sobre
      // essa largura que todo `font-size` do design foi escrito.
      expect(designCanvasWidth, 390.0);
    });

    test('na tela do mock não escala nada', () {
      expect(designScale(390), 1.0);
    });

    test('o emulador de 448px lógicos pede 15% a mais', () {
      // Densidade 480 medida no aparelho, logo 1344 / 3 = 448 px lógicos.
      final escala = designScale(448);
      expect(escala, closeTo(1.1487, 0.0005));
      // O título da lista ocupa 8,46% da largura no mock; com 33 px crus numa
      // tela de 448 cairia para 7,37%. Escalado, volta aos 8,46%.
      expect(33 * escala / 448, closeTo(33 / 390, 0.0001));
    });

    test('tela mais estreita que o mock não encolhe o texto', () {
      expect(designScale(360), 1.0);
    });

    test('o teto segura o outro extremo', () {
      // Num tablet a resposta certa é limitar a medida do texto, não inflar a
      // fonte até virar cartaz.
      expect(designScale(2000), 1.3);
    });

    test('largura inválida devolve o piso em vez de explodir', () {
      expect(designScale(double.infinity), 1.0);
      expect(designScale(0), 1.0);
      expect(designScale(-10), 1.0);
      expect(designScale(double.nan), 1.0);
    });

    test('a referência é parametrizável, para o teste não depender do mock', () {
      expect(designScale(200, referencia: 100, maximo: 5), 2.0);
      expect(designScale(100, referencia: 0), 1.0);
    });
  });

  group('DesignTextScaler', () {
    test('compõe com o escalonador do sistema em vez de substituí-lo', () {
      // Trocar o do sistema por um valor fixo apagaria o tamanho de fonte que a
      // pessoa escolheu no aparelho, que é ajuste de acessibilidade.
      const scaler = DesignTextScaler(
        sistema: TextScaler.linear(1.3),
        fator: 1.15,
      );
      expect(scaler.scale(16), closeTo(16 * 1.15 * 1.3, 0.001));
    });

    test('sem escalonamento do sistema sobra só o fator do design', () {
      const scaler = DesignTextScaler(
        sistema: TextScaler.noScaling,
        fator: 1.15,
      );
      expect(scaler.scale(16), closeTo(18.4, 0.001));
    });

    test('igualdade evita reconstruir a árvore sem motivo', () {
      const a = DesignTextScaler(sistema: TextScaler.noScaling, fator: 1.15);
      const b = DesignTextScaler(sistema: TextScaler.noScaling, fator: 1.15);
      const c = DesignTextScaler(sistema: TextScaler.noScaling, fator: 1.2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('DesignTypography', () {
    testWidgets('mede a tela e instala o escalonador na subárvore', (
      tester,
    ) async {
      late TextScaler visto;
      tester.view.physicalSize = const Size(1344, 2992);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              DesignTypography(child: child ?? const SizedBox.shrink()),
          home: Builder(
            builder: (context) {
              visto = MediaQuery.textScalerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(visto.scale(16), closeTo(16 * 448 / 390, 0.01));
    });
  });
}
