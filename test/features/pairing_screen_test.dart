import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/platform_pairing.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';

Widget _app(FakeGatewayRepository? gateway) {
  final router = buildAppRouter(initialLocation: '/pairing');
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

FakeGatewayRepository _gateway() => FakeGatewayRepository()
  ..pedidosDeAcesso = const [
    PairingRequest(
      platform: 'telegram',
      requestId: 'abcdef0123456789',
      userId: '1001',
      userName: 'Ana Teste',
      ageMinutes: 5,
    ),
    PairingRequest(platform: 'whatsapp', userId: '2002', ageMinutes: 90),
  ]
  ..acessosAprovados = [
    PairedUser(
      platform: 'telegram',
      userId: '3003',
      userName: 'Bruno Teste',
      approvedAt: DateTime(2026, 10, 12),
    ),
  ];

void main() {
  test('rótulo de plataforma', () {
    expect(platformLabel('whatsapp'), 'WhatsApp');
    expect(platformLabel('email'), 'E-mail');
    expect(platformLabel('zulip'), 'Zulip');
  });

  testWidgets('aprovar pede confirmação dizendo o que libera', (tester) async {
    final gateway = _gateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(find.text('Telegram · id 1001 · há 5 min'), findsOneWidget);
    expect(
      find.text('Pedido antigo: aprove pelo código no computador.'),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('pairing-approve-abcdef0123456789')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dar acesso a Ana Teste?'), findsOneWidget);
    expect(find.textContaining('pelo Telegram'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(gateway.acoesDeAcesso, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('pairing-approve-abcdef0123456789')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pairing-confirm')));
    await tester.pumpAndSettle();

    expect(gateway.acoesDeAcesso, ['approve:telegram:abcdef0123456789']);
    expect(
      find.byKey(const ValueKey('pairing-user-telegram-1001')),
      findsOneWidget,
    );
  });

  testWidgets('revogar e recusar todos também confirmam', (tester) async {
    final gateway = _gateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pairing-revoke-3003')));
    await tester.pumpAndSettle();
    expect(find.text('Revogar o acesso de Bruno Teste?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('pairing-confirm')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('pairing-clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pairing-confirm')));
    await tester.pumpAndSettle();

    expect(gateway.acoesDeAcesso, ['revoke:telegram:3003', 'clear']);
    expect(find.text('Nenhum pedido pendente.'), findsOneWidget);
    expect(find.text('Ninguém aprovado ainda.'), findsOneWidget);
  });

  testWidgets('sem Dashboard explica', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();
    expect(
      find.text('Conecte o Dashboard para ver os pedidos de acesso.'),
      findsOneWidget,
    );
  });
}
