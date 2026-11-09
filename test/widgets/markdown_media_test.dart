import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/features/chat/widgets/hermes_markdown.dart';

import '../support/fake_gateway_repository.dart';

/// PNG 1x1 transparente.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  ),
);

const _caminho = '/root/.hermes/screenshots/captura_1.png';

Future<void> _montar(
  WidgetTester tester,
  String markdown, {
  FakeGatewayRepository? gateway,
  bool streaming = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        if (gateway != null)
          gatewayRepositoryProvider.overrideWithValue(gateway),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: HermesMarkdown(markdown, streaming: streaming),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'MEDIA isolado conserva nome completo com espaços no bloco de download',
    (tester) async {
      await _montar(
        tester,
        'MEDIA:/srv/Projeto exemplo/Orçamento final.md',
        gateway: FakeGatewayRepository(),
      );
      expect(find.text('Orçamento final.md'), findsOneWidget);
      expect(
        find.text('/srv/Projeto exemplo/Orçamento final.md'),
        findsOneWidget,
      );
      expect(find.text('Baixar arquivo'), findsOneWidget);
    },
  );

  testWidgets('MEDIA: de imagem vira figura lida pelo Dashboard e amplia', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()..midias[_caminho] = _png;
    await _montar(
      tester,
      'Aqui está a tela:\n\nMEDIA:$_caminho',
      gateway: gateway,
    );

    expect(gateway.midiasLidas, [_caminho]);
    expect(find.byKey(const ValueKey('agent-media-image')), findsOneWidget);
    expect(find.text('captura_1.png'), findsOneWidget);
    expect(find.textContaining('MEDIA:', findRichText: true), findsNothing);

    await tester.tap(find.byTooltip('Ampliar imagem'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('image-viewer-close')), findsOneWidget);
    expect(find.text(_caminho), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('image-viewer-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('image-viewer-close')), findsNothing);
  });

  testWidgets('sem Dashboard mostra a referência sem quebrar a mensagem', (
    tester,
  ) async {
    await _montar(tester, 'Antes MEDIA:$_caminho depois.');

    expect(find.text('captura_1.png'), findsOneWidget);
    expect(find.text('Conecte o Dashboard para ver a imagem.'), findsOneWidget);
    expect(find.text(_caminho), findsOneWidget);
    expect(find.byKey(const ValueKey('agent-media-retry')), findsNothing);
    expect(find.textContaining('depois.', findRichText: true), findsOneWidget);
  });

  testWidgets('imagem que sumiu do servidor diz isso, sem tentar de novo', (
    tester,
  ) async {
    await _montar(tester, 'MEDIA:$_caminho', gateway: FakeGatewayRepository());

    expect(find.text('A imagem não está mais no servidor.'), findsOneWidget);
    expect(find.byKey(const ValueKey('agent-media-retry')), findsNothing);
  });

  testWidgets('arquivo que não é imagem fica como referência, sem leitura', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository();
    await _montar(
      tester,
      '**MEDIA:/root/.hermes/cache/relatorio.pdf**',
      gateway: gateway,
    );

    expect(find.text('relatorio.pdf'), findsOneWidget);
    expect(find.text('Arquivo no servidor'), findsOneWidget);
    expect(gateway.midiasLidas, isEmpty);
  });

  testWidgets('diretiva em código continua texto', (tester) async {
    final gateway = FakeGatewayRepository();
    await _montar(
      tester,
      'Use `MEDIA:/tmp/a.png` assim:\n\n```\nMEDIA:/tmp/b.png\n```',
      gateway: gateway,
    );

    expect(gateway.midiasLidas, isEmpty);
    expect(find.byKey(const ValueKey('agent-media-image')), findsNothing);
  });

  testWidgets('na cauda do streaming espera o caminho terminar', (
    tester,
  ) async {
    final gateway = FakeGatewayRepository()..midias[_caminho] = _png;
    await _montar(
      tester,
      'MEDIA:/root/.hermes/scr',
      gateway: gateway,
      streaming: true,
    );

    expect(find.text('Recebendo arquivo…'), findsOneWidget);
    expect(gateway.midiasLidas, isEmpty);

    await _montar(tester, 'MEDIA:$_caminho', gateway: gateway);
    expect(gateway.midiasLidas, [_caminho]);
  });

  testWidgets('imagem em data URL vira figura ampliável', (tester) async {
    await _montar(
      tester,
      '![gráfico](data:image/png;base64,${base64Encode(_png)})',
    );
    // A decodificação real só anda fora do relógio falso do teste.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ampliar imagem'), findsOneWidget);
    expect(find.textContaining('indisponível'), findsNothing);
  });
}
