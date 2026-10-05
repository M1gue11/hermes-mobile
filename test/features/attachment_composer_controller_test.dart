import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/repositories/attachment_source.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';
import 'package:hermes_mobile/features/chat/attachment_composer_controller.dart';

void main() {
  test('limpar composer vazio não inicializa serviços de plataforma', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () =>
          container.read(attachmentComposerControllerProvider.notifier).clear(),
      returnsNormally,
    );
  });

  test('seleciona arquivo e prepara referencia antes da legenda', () async {
    final source = _FakeAttachmentSource(picked: _file());
    final gateway = _FakeGatewayRepository();
    final container = _container(source: source, gateway: gateway);
    addTearDown(container.dispose);
    final controller = container.read(
      attachmentComposerControllerProvider.notifier,
    );

    await controller.pickFile();
    expect(
      container.read(attachmentComposerControllerProvider).attachments,
      hasLength(1),
    );

    final input = await controller.prepareInput(
      storedSessionId: 'session-1',
      caption: 'Resuma, por favor.',
    );

    expect(
      input,
      '@file:.hermes/desktop-attachments/relatorio.pdf\n\n'
      'Resuma, por favor.',
    );
    expect(gateway.attachedSessionIds, ['session-1']);
    expect(
      container
          .read(attachmentComposerControllerProvider)
          .attachments
          .single
          .status,
      ComposerAttachmentStatus.uploaded,
    );
  });

  test('grava audio e envia a transcricao como fala', () async {
    final source = _FakeAttachmentSource(recorded: _audio());
    final gateway = _FakeGatewayRepository(
      transcript: 'Lembre de comprar pão.',
    );
    final container = _container(source: source, gateway: gateway);
    addTearDown(container.dispose);
    final controller = container.read(
      attachmentComposerControllerProvider.notifier,
    );

    await controller.startRecording();
    expect(
      container.read(attachmentComposerControllerProvider).recording,
      isTrue,
    );
    await controller.stopRecording();

    final input = await controller.prepareInput(
      storedSessionId: 'session-1',
      caption: 'E marque como urgente.',
    );

    expect(input, 'Lembre de comprar pão.\n\nE marque como urgente.');
    expect(gateway.transcribedNames, ['voz.m4a']);
    expect(gateway.attachedSessionIds, isEmpty);
  });

  test('login exigido preserva o anexo para tentar novamente', () async {
    final source = _FakeAttachmentSource(picked: _file());
    final gateway = _FakeGatewayRepository(requireAuthentication: true);
    final container = _container(source: source, gateway: gateway);
    addTearDown(container.dispose);
    final controller = container.read(
      attachmentComposerControllerProvider.notifier,
    );

    await controller.pickFile();
    await expectLater(
      controller.prepareInput(storedSessionId: 'session-1', caption: ''),
      throwsA(isA<GatewayAuthenticationRequired>()),
    );

    final state = container.read(attachmentComposerControllerProvider);
    expect(state.attachments, hasLength(1));
    expect(state.attachments.single.status, ComposerAttachmentStatus.ready);
    expect(state.busy, isFalse);
    expect(state.error, isNull);
  });

  test(
    'limpar descarta a gravação preparada, mas delega a política à fonte',
    () async {
      final source = _FakeAttachmentSource(recorded: _audio());
      final container = _container(
        source: source,
        gateway: _FakeGatewayRepository(),
      );
      addTearDown(container.dispose);
      final controller = container.read(
        attachmentComposerControllerProvider.notifier,
      );

      await controller.startRecording();
      await controller.stopRecording();
      controller.clear();
      await Future<void>.delayed(Duration.zero);

      expect(source.discardedIds, ['audio-1']);
      expect(
        container.read(attachmentComposerControllerProvider).attachments,
        isEmpty,
      );
    },
  );
}

ProviderContainer _container({
  required AttachmentSource source,
  required GatewayRepository gateway,
}) => ProviderContainer(
  overrides: [
    attachmentSourceProvider.overrideWithValue(source),
    gatewayRepositoryProvider.overrideWithValue(gateway),
  ],
);

ComposerAttachment _file() => ComposerAttachment(
  id: 'file-1',
  name: 'relatorio.pdf',
  mimeType: 'application/pdf',
  bytes: Uint8List.fromList([1, 2, 3]),
);

ComposerAttachment _audio() => ComposerAttachment(
  id: 'audio-1',
  name: 'voz.m4a',
  mimeType: 'audio/mp4',
  bytes: Uint8List.fromList([4, 5, 6]),
  kind: ComposerAttachmentKind.audio,
);

final class _FakeAttachmentSource implements AttachmentSource {
  _FakeAttachmentSource({this.picked, this.recorded});

  final ComposerAttachment? picked;
  final ComposerAttachment? recorded;
  bool recording = false;
  final List<String> discardedIds = [];

  @override
  Future<void> cancelRecording() async => recording = false;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> discard(ComposerAttachment attachment) async {
    discardedIds.add(attachment.id);
  }

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<ComposerAttachment?> pickFile() async => picked;

  @override
  Future<void> startRecording() async => recording = true;

  @override
  Future<ComposerAttachment?> stopRecording() async {
    recording = false;
    return recorded;
  }
}

final class _FakeGatewayRepository implements GatewayRepository {
  _FakeGatewayRepository({
    this.transcript = 'Transcrição.',
    this.requireAuthentication = false,
  });

  final String transcript;
  final bool requireAuthentication;
  final List<String> attachedSessionIds = [];
  final List<String> transcribedNames = [];

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
    if (requireAuthentication) throw const GatewayAuthenticationRequired();
    attachedSessionIds.add(storedSessionId);
    return attachment.copyWith(
      status: ComposerAttachmentStatus.uploaded,
      refText: '@file:.hermes/desktop-attachments/${attachment.name}',
    );
  }

  @override
  Future<bool> hasSession() async => !requireAuthentication;

  @override
  Future<List<SessionMessage>> conversationHistory({
    required String storedSessionId,
  }) async => const [];

  @override
  Future<GatewayLiveTurn> openLiveTurn({required String storedSessionId}) =>
      throw UnimplementedError();

  @override
  Future<List<GatewayProbeStep>> probeGateway({String? storedSessionId}) async =>
      const <GatewayProbeStep>[];


  @override
  Future<String> transcribeAudio(ComposerAttachment attachment) async {
    if (requireAuthentication) throw const GatewayAuthenticationRequired();
    transcribedNames.add(attachment.name);
    return transcript;
  }
}
