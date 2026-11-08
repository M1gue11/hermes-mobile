import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/features/machine/machine_screen.dart';
import 'package:hermes_mobile/features/machine/machine_session.dart';

/// Sessão parada na pergunta do A91, sem rede: registra as decisões.
class _PerguntandoHost extends MachineSession {
  final decisoes = <bool>[];

  @override
  MachineState build() => (
    stage: MachineStage.confirmandoHost,
    target: (host: 'hermes.tail.ts.net', port: 22, user: 'operador'),
    publicKeyLine: 'ssh-ed25519 AAAA hermes-mobile',
    fingerprint: 'SHA256:abc123',
    erro: null,
    hostKeyChanged: false,
  );

  @override
  void confiarHost() => decisoes.add(true);

  @override
  void recusarHost() => decisoes.add(false);
}

void main() {
  testWidgets('A91: primeira chave pede confirmação com a impressão digital', (
    tester,
  ) async {
    final sessao = _PerguntandoHost();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [machineSessionProvider.overrideWith(() => sessao)],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const MachineScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('CONFERIR CHAVE'), findsOneWidget);
    expect(find.text('SHA256:abc123'), findsOneWidget);
    expect(find.text('IMPRESSÃO DIGITAL FIXADA'), findsNothing);
    expect(find.byKey(const ValueKey('conectar-maquina')), findsNothing);

    for (final key in ['confiar-host', 'recusar-host']) {
      final botao = find.byKey(ValueKey(key));
      await tester.ensureVisible(botao);
      await tester.pumpAndSettle();
      await tester.tap(botao);
    }

    expect(sessao.decisoes, [true, false]);
  });
}
