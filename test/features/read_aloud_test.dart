import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/audio/speech_player.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/domain/repositories/speech_player.dart';
import 'package:hermes_mobile/features/chat/read_aloud_controller.dart';
import 'package:hermes_mobile/features/chat/widgets/read_aloud_action.dart';

import '../support/fake_gateway_repository.dart';

class _FakePlayer implements SpeechPlayer {
  final tocados = <int>[];
  var paradas = 0;
  final _fim = StreamController<void>.broadcast(sync: true);

  @override
  Future<void> play(Uint8List bytes, {required String mimeType}) async =>
      tocados.add(bytes.length);

  @override
  Future<void> stop() async => paradas++;

  @override
  Stream<void> get completed => _fim.stream;

  void terminar() => _fim.add(null);
}

ProviderContainer _container(FakeGatewayRepository gateway, _FakePlayer p) {
  final container = ProviderContainer(
    overrides: [
      gatewayRepositoryProvider.overrideWithValue(gateway),
      speechPlayerProvider.overrideWithValue(p),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('texto falado sai sem marcação nem entregas de arquivo', () {
    expect(
      speakableText('# Pronto\n\n**Feito**, veja MEDIA:/tmp/a.png agora.'),
      allOf(
        isNot(contains('#')),
        isNot(contains('**')),
        isNot(contains('MEDIA')),
      ),
    );
    final longo = List.filled(800, 'Frase curta aqui.').join(' ');
    final falado = speakableText(longo);
    expect(falado.length, lessThanOrEqualTo(readAloudMaxChars));
    expect(falado, endsWith('.'));
  });

  test('toca, para no segundo toque e volta ao fim do áudio', () async {
    final gateway = FakeGatewayRepository();
    final player = _FakePlayer();
    final c = _container(gateway, player);
    final notifier = c.read(readAloudProvider.notifier);

    await notifier.toggle('m1', 'Olá');
    expect(c.read(readAloudProvider), (
      messageId: 'm1',
      phase: ReadAloudPhase.playing,
    ));
    expect(gateway.falas, ['Olá']);
    expect(player.tocados, [3]);

    player.terminar();
    expect(c.read(readAloudProvider), isNull);

    await notifier.toggle('m1', 'Olá');
    await notifier.toggle('m1', 'Olá');
    expect(c.read(readAloudProvider), isNull);
    expect(player.tocados, [3, 3]);
  });

  test('síntese atrasada não toca por cima da escolha mais nova', () async {
    final gateway = FakeGatewayRepository()..sinteseSegura = Completer<void>();
    final player = _FakePlayer();
    final c = _container(gateway, player);
    final notifier = c.read(readAloudProvider.notifier);

    final primeira = notifier.toggle('m1', 'um');
    expect(c.read(readAloudProvider)?.phase, ReadAloudPhase.synthesizing);
    final segunda = notifier.toggle('m2', 'dois');
    gateway.sinteseSegura!.complete();
    await Future.wait([primeira, segunda]);

    expect(player.tocados, hasLength(1));
    expect(c.read(readAloudProvider)?.messageId, 'm2');
  });

  test('falha da síntese volta ao repouso e chega a quem tocou', () async {
    final gateway = FakeGatewayRepository()
      ..falhaAoFalar = const GatewayOperationException('No TTS provider');
    final c = _container(gateway, _FakePlayer());

    await expectLater(
      c.read(readAloudProvider.notifier).toggle('m1', 'x'),
      throwsA(isA<GatewayOperationException>()),
    );
    expect(c.read(readAloudProvider), isNull);
  });

  testWidgets('sem Dashboard a ação não aparece', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [speechPlayerProvider.overrideWithValue(_FakePlayer())],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const Scaffold(
            body: ReadAloudAction(messageId: 'm1', markdown: 'oi'),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ouvir-resposta')), findsNothing);
  });

  testWidgets('falha aparece com a causa do servidor', (tester) async {
    final gateway = FakeGatewayRepository()
      ..falhaAoFalar = const GatewayOperationException('No TTS provider');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gatewayRepositoryProvider.overrideWithValue(gateway),
          speechPlayerProvider.overrideWithValue(_FakePlayer()),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const Scaffold(
            body: ReadAloudAction(messageId: 'm1', markdown: 'oi'),
          ),
        ),
      ),
    );
    expect(find.text('OUVIR'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('ouvir-resposta')));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível gerar o áudio: No TTS provider'),
      findsOneWidget,
    );
    expect(find.text('OUVIR'), findsOneWidget);
  });
}
