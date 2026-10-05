import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/models/composer_attachment.dart';
import '../../domain/repositories/gateway_repository.dart';

part 'attachment_composer_controller.g.dart';

typedef AttachmentComposerState = ({
  List<ComposerAttachment> attachments,
  bool recording,
  bool busy,
  String? error,
});

@riverpod
class AttachmentComposerController extends _$AttachmentComposerController {
  @override
  AttachmentComposerState build() =>
      (attachments: const [], recording: false, busy: false, error: null);

  Future<void> pickFile() async {
    if (state.busy || state.recording) return;
    try {
      final picked = await ref.read(attachmentSourceProvider).pickFile();
      if (picked == null) return;
      state = (
        attachments: [...state.attachments, picked],
        recording: false,
        busy: false,
        error: null,
      );
    } on GatewayOperationException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Não foi possível abrir este arquivo.');
    }
  }

  Future<void> startRecording() async {
    if (state.busy || state.recording) return;
    try {
      await ref.read(attachmentSourceProvider).startRecording();
      state = (
        attachments: state.attachments,
        recording: true,
        busy: false,
        error: null,
      );
    } on GatewayOperationException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Não foi possível iniciar a gravação.');
    }
  }

  Future<void> stopRecording() async {
    if (!state.recording) return;
    try {
      final recording = await ref
          .read(attachmentSourceProvider)
          .stopRecording();
      state = (
        attachments: recording == null
            ? state.attachments
            : [...state.attachments, recording],
        recording: false,
        busy: false,
        error: recording == null ? 'A gravação ficou vazia.' : null,
      );
    } on GatewayOperationException catch (error) {
      state = (
        attachments: state.attachments,
        recording: false,
        busy: false,
        error: error.message,
      );
    } catch (_) {
      state = (
        attachments: state.attachments,
        recording: false,
        busy: false,
        error: 'Não foi possível concluir a gravação.',
      );
    }
  }

  Future<void> cancelRecording() async {
    await ref.read(attachmentSourceProvider).cancelRecording();
    state = (
      attachments: state.attachments,
      recording: false,
      busy: false,
      error: null,
    );
  }

  void remove(String id) {
    if (state.busy) return;
    final removed = state.attachments
        .where((item) => item.id == id)
        .firstOrNull;
    state = (
      attachments: state.attachments
          .where((attachment) => attachment.id != id)
          .toList(growable: false),
      recording: state.recording,
      busy: false,
      error: null,
    );
    if (removed != null) {
      unawaited(ref.read(attachmentSourceProvider).discard(removed));
    }
  }

  Future<String> prepareInput({
    required String storedSessionId,
    required String caption,
  }) async {
    if (state.attachments.isEmpty) return caption.trim();
    state = (
      attachments: state.attachments,
      recording: false,
      busy: true,
      error: null,
    );

    try {
      final gateway = ref.read(gatewayRepositoryProvider);
      final uploaded = <ComposerAttachment>[];
      final transcripts = <String>[];
      for (var index = 0; index < state.attachments.length; index++) {
        final attachment = state.attachments[index];
        _replace(
          attachment.copyWith(status: ComposerAttachmentStatus.uploading),
        );
        if (attachment.kind == ComposerAttachmentKind.audio) {
          transcripts.add(await gateway.transcribeAudio(attachment));
          _replace(
            attachment.copyWith(status: ComposerAttachmentStatus.uploaded),
          );
        } else {
          final result = await gateway.attachFile(
            storedSessionId: storedSessionId,
            attachment: attachment,
          );
          uploaded.add(result);
          _replace(result);
        }
      }
      final spoken = transcripts.join('\n\n');
      final visibleText = [
        spoken,
        caption.trim(),
      ].where((part) => part.isNotEmpty).join('\n\n');
      return composeGatewayAttachmentInput(visibleText, uploaded);
    } on GatewayAuthenticationRequired {
      state = (
        attachments: state.attachments
            .map(
              (item) => item.copyWith(status: ComposerAttachmentStatus.ready),
            )
            .toList(growable: false),
        recording: false,
        busy: false,
        error: null,
      );
      rethrow;
    } on GatewayOperationException catch (error) {
      _failUploading(error.message);
      rethrow;
    } catch (_) {
      const message = 'Não foi possível preparar os anexos.';
      _failUploading(message);
      throw const GatewayOperationException(message);
    }
  }

  Future<void> authenticate({
    required String baseUrl,
    required String username,
    required String password,
  }) => ref
      .read(gatewayRepositoryProvider)
      .authenticate(baseUrl: baseUrl, username: username, password: password);

  void clear() {
    final discarded = state.attachments;
    state = (attachments: const [], recording: false, busy: false, error: null);
    if (discarded.isEmpty) return;
    final source = ref.read(attachmentSourceProvider);
    for (final attachment in discarded) {
      unawaited(source.discard(attachment));
    }
  }

  void clearError() {
    state = (
      attachments: state.attachments,
      recording: state.recording,
      busy: state.busy,
      error: null,
    );
  }

  void _replace(ComposerAttachment replacement) {
    state = (
      attachments: [
        for (final item in state.attachments)
          if (item.id == replacement.id) replacement else item,
      ],
      recording: false,
      busy: state.busy,
      error: null,
    );
  }

  void _failUploading(String message) {
    state = (
      attachments: state.attachments
          .map(
            (item) => item.status == ComposerAttachmentStatus.uploading
                ? item.copyWith(
                    status: ComposerAttachmentStatus.failed,
                    error: message,
                  )
                : item,
          )
          .toList(growable: false),
      recording: false,
      busy: false,
      error: message,
    );
  }

  void _setError(String message) {
    state = (
      attachments: state.attachments,
      recording: state.recording,
      busy: false,
      error: message,
    );
  }
}
