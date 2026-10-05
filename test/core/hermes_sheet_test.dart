import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/core/theme/hermes_motion.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/core/widgets/hermes_sheet.dart';
import 'package:hermes_mobile/core/widgets/tap_scale.dart';

Future<void> montarSheet(
  WidgetTester tester, {
  bool disableAnimations = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showHermesSheet(
              context,
              title: 'Um título de folha suficientemente comprido',
              tag: 'cliente',
              child: const Text('Conteúdo da folha'),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sheet usa o vocabulário de entrada e saída do app', (
    tester,
  ) async {
    await montarSheet(tester);

    final route =
        ModalRoute.of(tester.element(find.text('Conteúdo da folha')))!
            as ModalBottomSheetRoute<void>;
    expect(route.useSafeArea, isTrue);
    expect(route.sheetAnimationStyle!.duration, HermesMotion.revelar);
    expect(
      route.sheetAnimationStyle!.reverseDuration,
      HermesMotion.saidaDe(HermesMotion.revelar),
    );
    expect(route.sheetAnimationStyle!.curve, HermesMotion.curvaChegada);
    expect(route.sheetAnimationStyle!.reverseCurve, HermesMotion.curvaPadrao);
  });

  testWidgets('sheet corta entrada e saída quando movimento é reduzido', (
    tester,
  ) async {
    await montarSheet(tester, disableAnimations: true);

    final route =
        ModalRoute.of(tester.element(find.text('Conteúdo da folha')))!
            as ModalBottomSheetRoute<void>;
    expect(route.sheetAnimationStyle, AnimationStyle.noAnimation);
  });

  testWidgets('texto ampliado empilha tag e preserva o título inteiro', (
    tester,
  ) async {
    await montarSheet(tester, textScale: 1.8);

    final title = find.byKey(const ValueKey('hermes-sheet-title'));
    final tag = find.byKey(const ValueKey('hermes-sheet-tag'));
    expect(title, findsOneWidget);
    expect(tag, findsOneWidget);
    expect(
      tester.getSemantics(title).getSemanticsData().flagsCollection.isHeader,
      isTrue,
    );
    expect(tester.getBottomLeft(title).dy, lessThan(tester.getTopLeft(tag).dy));

    final text = tester.widget<Text>(
      find.descendant(of: title, matching: find.byType(Text)),
    );
    expect(text.maxLines, isNull);
    expect(text.overflow, TextOverflow.visible);

    final tokens = HermesTokens.of(tester.element(tag));
    expect(tester.widget<Text>(tag).style!.color, tokens.dim);
  });

  testWidgets('TapScale só anuncia botão quando existe uma ação', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: Column(
            children: [
              const TapScale(
                key: ValueKey('static-tap-scale'),
                semanticsLabel: 'Somente leitura',
                child: Text('Estático'),
              ),
              TapScale(
                key: const ValueKey('active-tap-scale'),
                semanticsLabel: 'Executar',
                onTap: () {},
                onLongPress: () {},
                child: const Text('Ativo'),
              ),
            ],
          ),
        ),
      ),
    );

    final staticNode = tester.getSemantics(
      find.byKey(const ValueKey('static-tap-scale')),
    );
    final activeNode = tester.getSemantics(
      find.byKey(const ValueKey('active-tap-scale')),
    );
    expect(staticNode.getSemanticsData().flagsCollection.isButton, isFalse);
    expect(
      staticNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(activeNode.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(
      activeNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      activeNode.getSemanticsData().hasAction(SemanticsAction.longPress),
      isTrue,
    );
    semantics.dispose();
  });
}
