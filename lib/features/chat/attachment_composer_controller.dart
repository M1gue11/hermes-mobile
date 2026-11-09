import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/models/composer_attachment.dart';
import '../../domain/repositories/attachment_source.dart';
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
  AttachmentComposerState build() {
    // A fonte vive o app inteiro; o composer, só a tela. Sem isto, sair da
    // conversa no meio de uma gravação deixava o microfone ligado (A89).
    ref.onDispose(() {
      if (!_recording) return;
      _recording = false;
      unawaited(_source?.cancelRecording());
    });
    return (attachments: const [], recording: false, busy: false, error: null);
  }

  /// Espelho de `state.recording` que o `onDispose` pode ler.
  bool _recording = false;
  AttachmentSource? _source;

  @override
  set state(AttachmentComposerState value) {
    _recording = value.recording;
    super.state = value;
  }

  Future<void> pickFile() async {
    if (state.busy || state.recording) return;
    final full = composerBudgetProblem(state.attachments);
    if (full != null) return _setError(full);
    state = (
      attachments: state.attachments,
      recording: false,
      busy: true,
      error: null,
    );
    try {
      final source = ref.read(attachmentSourceProvider);
      final selection = await source.pickFiles(
        availableSlots: maxComposerAttachments - state.attachments.length,
        availableBytes:
            maxComposerTotalBytes -
            state.attachments.fold<int>(
              0,
              (sum, item) => sum + item.bytes.length,
            ),
      );
      if (!ref.mounted) {
        for (final picked in selection.attachments) {
          unawaited(source.discard(picked));
        }
        return;
      }
      final accepted = [...state.attachments];
      final errors = [...selection.errors];
      for (final picked in selection.attachments) {
        final over = composerBudgetProblem(accepted, adding: picked);
        if (over != null || picked.bytes.length > maxComposerAttachmentBytes) {
          unawaited(source.discard(picked));
          errors.add(
            '${picked.name}: ${over ?? 'excede o limite de 25 MB por arquivo.'}',
          );
        } else {
          accepted.add(picked);
        }
      }
      state = (
        attachments: accepted,
        recording: false,
        busy: false,
        error: errors.isEmpty ? null : errors.join('\n'),
      );
    } on GatewayOperationException catch (error) {
      if (ref.mounted) _selectionFailed(error.message);
    } catch (_) {
      if (ref.mounted) {
        _selectionFailed('Não foi possível abrir o seletor de arquivos.');
      }
    }
  }

  void _selectionFailed(String error) {
    state = (
      attachments: state.attachments,
      recording: false,
      busy: false,
      error: error,
    );
  }

  Future<void> startRecording() async {
    if (state.busy || state.recording) return;
    final full = composerBudgetProblem(state.attachments);
    if (full != null) return _setError(full);
    try {
      final source = ref.read(attachmentSourceProvider);
      _source = source;
      await source.startRecording();
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
      final source = ref.read(attachmentSourceProvider);
      final recording = await source.stopRecording();
      final over = recording == null
          ? null
          : composerBudgetProblem(state.attachments, adding: recording);
      if (over != null) {
        unawaited(source.discard(recording!));
        state = (
          attachments: state.attachments,
          recording: false,
          busy: false,
          error: over,
        );
        return;
      }
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

  /// O app saiu da frente ou outra tela cobriu a conversa. O Android não
  /// deixa gravar em segundo plano sem serviço próprio, então a gravação
  /// seguiria capturando silêncio; ela é descartada, com o motivo na tela.
  Future<void> interruptRecording() async {
    if (!state.recording) return;
    await cancelRecording();
    _setError('A gravação foi descartada ao sair da conversa.');
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
        // A84: o que já foi confirmado numa tentativa anterior não sobe de
        // novo. Arquivo só reaproveita na mesma conversa, porque o `@file:`
        // aponta para o workspace dela.
        final transcript = attachment.transcript;
        if (attachment.kind == ComposerAttachmentKind.audio &&
            transcript != null) {
          transcripts.add(transcript);
          _replace(
            attachment.copyWith(status: ComposerAttachmentStatus.uploaded),
          );
          continue;
        }
        if (attachment.kind == ComposerAttachmentKind.file &&
            attachment.refText != null &&
            attachment.uploadedSessionId == storedSessionId) {
          final reused = attachment.copyWith(
            status: ComposerAttachmentStatus.uploaded,
          );
          uploaded.add(reused);
          _replace(reused);
          continue;
        }
        _replace(
          attachment.copyWith(status: ComposerAttachmentStatus.uploading),
        );
        if (attachment.kind == ComposerAttachmentKind.audio) {
          final spoken = await gateway.transcribeAudio(attachment);
          transcripts.add(spoken);
          _replace(
            attachment.copyWith(
              status: ComposerAttachmentStatus.uploaded,
              transcript: spoken,
            ),
          );
        } else {
          final result = (await gateway.attachFile(
            storedSessionId: storedSessionId,
            attachment: attachment,
          )).copyWith(uploadedSessionId: storedSessionId);
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
