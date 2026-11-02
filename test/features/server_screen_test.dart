import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/router/app_router.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/server_health.dart';
import 'package:hermes_mobile/core/format/quantities.dart';
import 'package:hermes_mobile/features/server/server_labels.dart';
import 'package:hermes_mobile/features/server/server_provider.dart';

import '../support/fake_gateway_repository.dart';
import '../support/fake_hermes_repository.dart';

Widget _app(
  FakeGatewayRepository? gateway, {
  FakeHermesRepository? api,
  String location = '/server',
}) {
  final router = buildAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  return ProviderScope(
    retry: (_, _) => null,
    overrides: [
      hermesRepositoryProvider.overrideWithValue(api ?? FakeHermesRepository()),
      if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
      restartPollIntervalProvider.overrideWithValue(Duration.zero),
    ],
    child: MaterialApp.router(theme: AppTheme.build(), routerConfig: router),
  );
}

final _antes = GatewayRuntime(
  running: true,
  state: 'running',
  updatedAt: DateTime.utc(2026, 11, 2, 10),
  activeSessions: 2,
  platformsConfigured: 3,
  platformsConnected: 2,
);

void main() {
  test('rótulos de medida', () {
    expect(byteLabel(9800000000), '9,8 GB');
    expect(byteLabel(512), '512 B');
    expect(uptimeLabel(93784), '1 d 2 h');
    expect(compactCount(38200), '38,2 mil');
    expect(latencyLabel(1240), '1,2 s');
    expect(
      gatewayRuntimeMeta(_antes),
      '2 sessões · nenhum turno em andamento · 2 de 3 plataformas',
    );
  });

  testWidgets('mostra estado, prontidão e máquina', (tester) async {
    final gateway = FakeGatewayRepository()
      ..estados = [_antes]
      ..maquina = const HostStats(
        hostname: 'servidor',
        cpuPercent: 12,
        memoryPercent: 93,
        memoryUsedBytes: 14880000000,
        memoryTotalBytes: 16000000000,
      );
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    expect(find.text('Gateway rodando'), findsOneWidget);
    expect(find.text('Pronto para atender'), findsOneWidget);
    expect(find.text('Modelo'), findsOneWidget);
    expect(find.text('93%'), findsOneWidget);
    expect(find.textContaining('14,9 GB de 16,0 GB'), findsOneWidget);
  });

  testWidgets('reinício pede confirmação e acompanha até o gateway voltar', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()
      ..estados = [
        _antes,
        _antes,
        _antes.copyWith(running: false, state: 'stopping'),
        _antes.copyWith(
          state: 'running',
          updatedAt: DateTime.utc(2026, 11, 2, 10, 1),
        ),
      ];
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('server-restart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-restart')));
    await tester.pumpAndSettle();
    expect(find.text('Reiniciar o gateway?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(gateway.reinicios, 0);

    await tester.tap(find.byKey(const ValueKey('server-restart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-restart-confirm')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(gateway.reinicios, 1);
    expect(find.byKey(const ValueKey('restart-done')), findsOneWidget);
    expect(find.textContaining('Gateway de volta'), findsOneWidget);
  });

  testWidgets('gateway que não sobe mostra o motivo', (tester) async {
    final gateway = FakeGatewayRepository()
      ..estados = [
        _antes,
        _antes,
        const GatewayRuntime(
          state: 'startup_failed',
          exitReason: 'porta 8642 ocupada',
        ),
      ];
    await tester.pumpWidget(_app(gateway));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('server-restart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-restart')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('server-restart-confirm')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('restart-failed')), findsOneWidget);
    expect(
      find.text('O gateway não subiu: porta 8642 ocupada'),
      findsOneWidget,
    );
  });

  testWidgets('sem Dashboard o reinício fica desligado e diz por quê', (
    tester,
  ) async {
    await tester.pumpWidget(_app(null));
    await tester.pumpAndSettle();

    expect(
      find.text('Conecte o Dashboard para ver o estado do gateway.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('server-restart')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const ValueKey('server-restart')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('logs do mais novo para o mais antigo e filtro no servidor', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()
      ..linhasDeLog = [
        '2026-11-02 10:00:00,000 INFO agent: primeiro\n',
        '2026-11-02 10:00:05,000 ERROR tools.web: segundo\n',
      ];
    await tester.pumpWidget(_app(gateway, location: '/server/logs'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('segundo')).dy,
      lessThan(tester.getTopLeft(find.text('primeiro')).dy),
    );

    await tester.tap(find.byKey(const ValueKey('logs-level-ERROR')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('logs-search')), 'web');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(gateway.consultasDeLog.last, (
      file: GatewayLogFile.agent,
      level: GatewayLogLevel.error,
      search: 'web',
    ));
  });

  testWidgets('traceback longo abre recolhido e expande', (tester) async {
    final gateway = FakeGatewayRepository()
      ..linhasDeLog = [
        '2026-11-02 10:00:05,000 ERROR tools.web: falhou\n',
        for (var i = 1; i <= 12; i++) '  quadro $i\n',
      ];
    await tester.pumpWidget(_app(gateway, location: '/server/logs'));
    await tester.pumpAndSettle();

    expect(find.textContaining('quadro 5'), findsOneWidget);
    expect(find.textContaining('quadro 12'), findsNothing);
    expect(find.text('Mostrar tudo (13 linhas)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('log-entry-toggle')));
    await tester.pumpAndSettle();
    expect(find.textContaining('quadro 12'), findsOneWidget);
    expect(find.text('Recolher'), findsOneWidget);
  });
}
