import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/format/quantities.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/usage_summary.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';

Widget _app(FakeGatewayRepository? gateway) {
  final router = buildAppRouter(initialLocation: '/usage');
  addTearDown(router.dispose);
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [
      hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
      if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
    ],
    child: MaterialApp.router(theme: AppTheme.build(), routerConfig: router),
  );
}

UsageSummary _uso(int days) {
  final hoje = DateTime.now();
  return UsageSummary(
    periodDays: days,
    inputTokens: 38000,
    outputTokens: 200,
    estimatedCost: 1.5,
    actualCost: 1.24,
    sessions: 4,
    daily: [
      UsageDay(
        day: DateTime(hoje.year, hoje.month, hoje.day),
        inputTokens: 38000,
        outputTokens: 200,
        actualCost: 1.24,
        sessions: 4,
      ),
    ],
    byModel: const [
      ModelUsage(model: 'gpt-6.1-sol', inputTokens: 38000, outputTokens: 200),
    ],
  );
}

void main() {
  test('rótulos de quantidade', () {
    expect(compactCount(38200), '38,2 mil');
    expect(compactCount(1000000), '1 mi');
    expect(usdLabel(0.004), '< US\$ 0,01');
    expect(usdLabel(12.4), 'US\$ 12,40');
  });

  testWidgets('mostra custo cobrado, série e modelos; troca o período', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()..usoPorPeriodo = _uso;
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(gateway.periodosPedidos, [30]);
    expect(find.text('US\$ 1,24'), findsOneWidget);
    expect(find.textContaining('custo cobrado'), findsOneWidget);
    expect(find.textContaining('estimado US\$ 1,50'), findsOneWidget);
    expect(find.text('gpt-6.1-sol'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('usage-period-7')));
    await tester.pumpAndSettle();
    expect(gateway.periodosPedidos, [30, 7]);
  });

  testWidgets('tocar no último dia mostra os números dele', (tester) async {
    final gateway = FakeGatewayRepository()..usoPorPeriodo = _uso;
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    final bars = find.byKey(const ValueKey('usage-daily'));
    final box = tester.getRect(bars);
    await tester.tapAt(Offset(box.right - 2, box.center.dy));
    await tester.pumpAndSettle();

    final caption = tester.widget<Text>(
      find.byKey(const ValueKey('usage-daily-caption')),
    );
    expect(caption.data, contains('38,2 mil tokens'));
    expect(caption.data, contains('4 sessões'));
  });

  testWidgets('sem custo registrado o destaque são os tokens', (tester) async {
    final gateway = FakeGatewayRepository()
      ..usoPorPeriodo = (days) => UsageSummary(
        periodDays: days,
        inputTokens: 40000000,
        outputTokens: 100000,
        sessions: 128,
        byModel: const [
          ModelUsage(model: 'a', inputTokens: 3000),
          ModelUsage(model: 'b', inputTokens: 1000),
        ],
      );
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(find.text('40,1 mi tokens'), findsOneWidget);
    expect(find.textContaining('sem custo registrado'), findsOneWidget);
    expect(find.textContaining('US\$'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('25%'),
      300,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('usage-list')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('período vazio diz que não houve sessão', (tester) async {
    await tester.pumpWidget(_app(FakeGatewayRepository()));
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma sessão nos últimos 30 dias.'), findsOneWidget);
  });

  testWidgets('sem Dashboard pede para conectá-lo', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();
    expect(
      find.text('Conecte o Dashboard para ver o uso do servidor.'),
      findsOneWidget,
    );
  });
}
