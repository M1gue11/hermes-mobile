import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/widgets/hermes_startup_splash.dart';

void main() {
  testWidgets('mantém a assinatura até a transição para o conteúdo', (
    tester,
  ) async {
    await tester.pumpWidget(
      HermesStartupSplash(
        timelineDuration: const Duration(milliseconds: 100),
        handoffPause: const Duration(milliseconds: 10),
        fadeDuration: const Duration(milliseconds: 20),
        child: const ColoredBox(key: Key('conteudo'), color: Colors.white),
      ),
    );

    expect(find.byType(HermesStartupSplash), findsOneWidget);
    expect(find.byType(CustomPaint), findsNWidgets(2));
    expect(find.byKey(const Key('conteudo')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(
      Directionality.of(tester.element(find.byType(Stack).first)),
      TextDirection.ltr,
    );

    // O tempo falso avança o controlador, a pausa e o fade em quadros
    // distintos; em um aparelho esses três estágios acontecem continuamente.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CustomPaint), findsNothing);
  });

  testWidgets('não anima quando o sistema pede menos movimento', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: HermesStartupSplash(
          child: const ColoredBox(key: Key('conteudo'), color: Colors.white),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CustomPaint), findsNothing);
    expect(find.byKey(const Key('conteudo')), findsOneWidget);
  });
}
