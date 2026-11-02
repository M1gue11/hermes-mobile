import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/server_tools.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';

Widget _app(FakeGatewayRepository? gateway) {
  final router = buildAppRouter(initialLocation: '/tools');
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
  ..toolsets = const [
    ToolsetSetting(
      name: 'web',
      label: 'Web',
      description: 'Busca e leitura de páginas',
      enabled: true,
      toolCount: 3,
    ),
    ToolsetSetting(
      name: 'image_gen',
      label: 'Imagens',
      configured: false,
      toolCount: 1,
    ),
  ]
  ..servidoresMcp = const [
    McpServerSetting(name: 'obsidian', transport: 'stdio'),
    McpServerSetting(name: 'cua', transport: 'stdio', plugin: 'computer-use'),
  ];

void main() {
  testWidgets('liga um toolset e mostra quando falta credencial', (
    tester,
  ) async {
    final gateway = _gateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(find.textContaining('sem credencial'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toolset-switch-image_gen')));
    await tester.pumpAndSettle();

    expect(gateway.alternanciasDeFerramentas, ['toolset:image_gen:true']);
    expect(
      tester
          .widget<Switch>(
            find.byKey(const ValueKey('toolset-switch-image_gen')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('recusa do servidor volta a chave e explica', (tester) async {
    final gateway = _gateway()
      ..falhaAoAlternar = const GatewayOperationException('Unknown toolset');
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('toolset-switch-web')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('toolset-switch-web')))
          .value,
      isTrue,
    );
    expect(find.text('Unknown toolset'), findsOneWidget);
  });

  testWidgets('MCP de plugin fica travado e o teste mostra as ferramentas', (
    tester,
  ) async {
    final gateway = _gateway();
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('mcp-test-obsidian')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<Switch>(find.byKey(const ValueKey('mcp-switch-cua')))
          .onChanged,
      isNull,
    );

    await tester.tap(find.byKey(const ValueKey('mcp-switch-obsidian')));
    await tester.pumpAndSettle();
    expect(gateway.alternanciasDeFerramentas, ['mcp:obsidian:false']);

    await tester.tap(find.byKey(const ValueKey('mcp-test-obsidian')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Conectou · 1 ferramenta'), findsOneWidget);
  });

  testWidgets('sem Dashboard diz o motivo uma vez', (tester) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(
      find.text('Conecte o Dashboard para gerenciar as ferramentas.'),
      findsOneWidget,
    );
  });
}
