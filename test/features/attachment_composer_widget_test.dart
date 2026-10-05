import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/app_theme.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/repositories/attachment_source.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/features/chat/chat_controller.dart';
import 'package:hermes_mobile/features/chat/chat_screen.dart';
import 'package:hermes_mobile/main.dart';

import '../support/fake_hermes_repository.dart';
import '../support/memory_active_run_store.dart';
import 'package:hermes_mobile/features/chat/launch_provider.dart';
import '../support/stub_chat_launch.dart';

void main() {
  testWidgets('anexa arquivo, envia e mostra card sem expor @file', (
    tester,
  ) async {
    final source = _WidgetAttachmentSource();
    final gateway = _WidgetGatewayRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
          activeRunStoreProvider.overrideWithValue(MemoryActiveRunStore()),
          attachmentSourceProvider.overrideWithValue(source),
          gatewayRepositoryProvider.overrideWithValue(gateway),
        ],
        child: const HermesApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Conversa persistida'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey('composer-attach')));
    await tester.pump();

    expect(find.text('relatorio.pdf'), findsOneWidget);
    expect(find.text('3 B'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Resuma este arquivo.');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    for (var index = 0; index < 12; index++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(find.text('Resuma este arquivo.'), findsWidgets);
    expect(find.text('relatorio.pdf'), findsOneWidget);
    expect(find.textContaining('@file:'), findsNothing);
    expect(gateway.attachedSessionIds, ['session-1']);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('grava, conclui e deixa a voz pronta no composer', (
    tester,
  ) async {
    final source = _WidgetAttachmentSource();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatLaunchProvider.overrideWithValue(StubChatLaunch()),
          hermesRepositoryProvider.overrideWithValue(FakeHermesRepository()),
          attachmentSourceProvider.overrideWithValue(source),
          gatewayRepositoryProvider.overrideWithValue(
            _WidgetGatewayRepository(),
          ),
        ],
        child: MaterialApp(theme: AppTheme.build(), home: const ChatScreen()),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('composer-record')));
    await tester.pump();
    expect(find.byKey(const ValueKey('composer-recording')), findsOneWidget);
    expect(find.textContaining('GRAVANDO'), findsOneWidget);

    // A43: as faixas empilhadas da barra são a mesma superfície em estados
    // diferentes, então têm de ter o mesmo raio e a mesma grade. Antes a
    // gravação saía com raio 12 e folga à esquerda de 12, contra 22 e 6 do
    // campo logo abaixo, e o usuário viu as duas desalinhadas num print.
    BorderRadius raioDe(Key chave) =>
        ((tester
                        .widget<Container>(
                          find
                              .descendant(
                                of: find.byKey(chave),
                                matching: find.byType(Container),
                              )
                              .first,
                        )
                        .decoration!
                    as BoxDecoration)
                .borderRadius!)
            .resolve(TextDirection.ltr);

    expect(
      raioDe(const ValueKey('composer-recording')),
      raioDe(const ValueKey('composer-field')),
      reason: 'faixas empilhadas não podem ter arredondamentos diferentes',
    );

    final faixaGravando = tester.getRect(
      find.byKey(const ValueKey('composer-recording')),
    );
    final faixaCampo = tester.getRect(
      find.byKey(const ValueKey('composer-field')),
    );
    expect(faixaGravando.left, faixaCampo.left);
    expect(faixaGravando.right, faixaCampo.right);

    // A coluna da esquerda: o ponto de gravação cai onde o `+` cai.
    expect(
      tester.getRect(find.byTooltip('Concluir gravação')).right,
      tester.getRect(find.byKey(const ValueKey('composer-send'))).right,
      reason: 'os botões das duas faixas ficam na mesma coluna da direita',
    );

    await tester.tap(find.byTooltip('Concluir gravação'));
    await tester.pump();
    expect(find.byKey(const ValueKey('composer-recording')), findsNothing);
    expect(find.text('voz.m4a'), findsOneWidget);
    expect(find.text('3 B'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

final class _WidgetAttachmentSource implements AttachmentSource {
  @override
  Future<void> cancelRecording() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> discard(ComposerAttachment attachment) async {}

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<ComposerAttachment?> pickFile() async => ComposerAttachment(
    id: 'file-1',
    name: 'relatorio.pdf',
    mimeType: 'application/pdf',
    bytes: Uint8List.fromList([1, 2, 3]),
  );

  @override
  Future<void> startRecording() async {}

  @override
  Future<ComposerAttachment?> stopRecording() async => ComposerAttachment(
    id: 'audio-1',
    name: 'voz.m4a',
    mimeType: 'audio/mp4',
    bytes: Uint8List.fromList([4, 5, 6]),
    kind: ComposerAttachmentKind.audio,
  );
}

final class _WidgetGatewayRepository implements GatewayRepository {
  final List<String> attachedSessionIds = [];

  @override
  Future<void> authenticate({
    required String baseUrl,
    required String username,
    required String password,
  }) async {}

  @override
  Future<ComposerAttachment> attachFile({
    required String storedSessionId,
    required ComposerAttachment attachment,
  }) async {
    attachedSessionIds.add(storedSessionId);
    return attachment.copyWith(
      status: ComposerAttachmentStatus.uploaded,
      refText: '@file:.hermes/desktop-attachments/${attachment.name}',
    );
  }

  @override
  Future<bool> hasSession() async => true;

  @override
  Future<List<SessionMessage>> conversationHistory({
    required String storedSessionId,
  }) async => const [];

  @override
  Future<GatewayLiveTurn> openLiveTurn({required String storedSessionId}) =>
      throw UnimplementedError();

  @override
  Future<List<GatewayProbeStep>> probeGateway({
    String? storedSessionId,
  }) async => const <GatewayProbeStep>[];

  @override
  Future<String> transcribeAudio(ComposerAttachment attachment) async =>
      'Mensagem de voz transcrita.';
}
