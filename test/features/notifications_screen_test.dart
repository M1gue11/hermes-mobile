import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/features/notifications/notifications_screen.dart';
import 'package:hermes_mobile/features/notifications/push_controller.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';
import '../support/fake_push.dart';

void main() {
  late FakePushTransport transport;
  late FakeLocalNotifier notifier;
  late MemoryPushRegistrationStore store;
  late FakeGatewayRepository gateway;

  setUp(() {
    transport = FakePushTransport();
    notifier = FakeLocalNotifier();
    store = MemoryPushRegistrationStore();
    gateway = FakeGatewayRepository();
  });

  Widget app({double textScale = 1}) {
    final router = buildAppRouter(initialLocation: '/notifications');
    addTearDown(router.dispose);
    return ProviderScope(
      retry: (_, _) => null,
      overrides: [
        hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
        gatewayRepositoryProvider.overrideWithValue(gateway),
        pushTransportProvider.overrideWithValue(transport),
        localNotifierProvider.overrideWithValue(notifier),
        pushRegistrationStoreProvider.overrideWithValue(store),
        pushEndpointTimeoutProvider.overrideWithValue(
          const Duration(milliseconds: 50),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.build(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    );
  }

  test('rótulos', () {
    expect(distributorLabel('io.heckel.ntfy'), 'ntfy');
    expect(distributorLabel('io.heckel.ntfy.fdroid'), 'ntfy');
    expect(
      distributorLabel('org.unifiedpush.distributor.nextpush'),
      'nextpush',
    );
    expect(
      testOutcome((ok: true, status: 201, encrypted: true, gone: false)),
      contains('alguns segundos'),
    );
    expect(
      testOutcome((ok: false, status: 0, encrypted: false, gone: false)),
      'O Hermes não alcançou o servidor ntfy.',
    );
    expect(
      testOutcome((ok: false, status: 403, encrypted: false, gone: false)),
      'O servidor ntfy respondeu 403.',
    );
  });

  testWidgets('ligar mostra cada elo e permite testar', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Distribuidor'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('push-switch')));
    await tester.pumpAndSettle();

    expect(find.text('ntfy'), findsOneWidget);
    expect(find.text('ntfy.example.org'), findsOneWidget);
    expect(find.text('mobile-push, aparelho registrado'), findsOneWidget);
    expect(find.text('cifrado até o aparelho'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('push-test')));
    await tester.pumpAndSettle();
    expect(gateway.testesDePush, ['phone-0001']);
    expect(find.byKey(const ValueKey('push-test-result')), findsOneWidget);
  });

  testWidgets('sem distribuidor oferece instalar o ntfy', (tester) async {
    transport.installed = const [];
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('push-switch')));
    await tester.pumpAndSettle();

    expect(find.text('nenhum instalado'), findsOneWidget);
    expect(find.byKey(const ValueKey('push-install-ntfy')), findsOneWidget);

    transport.installed = const ['io.heckel.ntfy'];
    await tester.tap(find.byKey(const ValueKey('push-retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('push-test')), findsOneWidget);
  });

  testWidgets('plugin ausente explica como instalar', (tester) async {
    gateway.pluginDePush = false;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('push-switch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-plugin-missing')), findsOneWidget);
    expect(find.text('não encontrado'), findsOneWidget);
  });

  testWidgets('permissão negada explica onde liberar', (tester) async {
    notifier.allowed = false;
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('push-switch')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('push-permission')), findsOneWidget);
    final toggle = tester.widget<Switch>(
      find.byKey(const ValueKey('push-switch')),
    );
    expect(toggle.value, isFalse);
  });

  testWidgets('texto ampliado não estoura as linhas de estado', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(textScale: 2));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('push-switch'));
    await tester.scrollUntilVisible(toggle, 120);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('push-test')),
      120,
    );

    expect(tester.takeException(), isNull);
  });
}
