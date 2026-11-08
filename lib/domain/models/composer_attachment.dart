import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'composer_attachment.freezed.dart';

enum ComposerAttachmentKind { file, audio }

enum ComposerAttachmentStatus { ready, uploading, uploaded, failed }

@freezed
abstract class ComposerAttachment with _$ComposerAttachment {
  const factory ComposerAttachment({
    required String id,
    required String name,
    required String mimeType,
    required Uint8List bytes,
    @Default(ComposerAttachmentKind.file) ComposerAttachmentKind kind,
    @Default(ComposerAttachmentStatus.ready) ComposerAttachmentStatus status,
    String? localPath,
    String? refText,

    /// Sessão em que [refText] foi confirmado. A referência é relativa ao
    /// workspace dela, então só vale para reenviar na mesma conversa (A84).
    String? uploadedSessionId,

    /// Transcrição já obtida de uma gravação; um retry não transcreve de novo.
    String? transcript,
    String? error,
  }) = _ComposerAttachment;
}

/// Limite conservador para não multiplicar uma alocação móvel grande em base64.
/// A transcrição do Dashboard impõe o mesmo teto para áudio.
const maxComposerAttachmentBytes = 25 * 1024 * 1024;

/// Teto do conjunto de uma mensagem (A87). Os bytes ficam em memória até o
/// envio e viram base64 (mais um terço) na hora; sem teto, anexos somados
/// esgotavam a memória de um celular modesto.
const maxComposerAttachments = 10;
const maxComposerTotalBytes = 50 * 1024 * 1024;

/// Por que [current] não comporta mais um anexo; `null` quando cabe.
/// Sem [adding], pergunta só se ainda cabe algum (antes de abrir o seletor).
String? composerBudgetProblem(
  List<ComposerAttachment> current, {
  ComposerAttachment? adding,
}) {
  if (current.length >= maxComposerAttachments) {
    return 'Limite de $maxComposerAttachments anexos por mensagem.';
  }
  if (adding == null) return null;
  final total = current.fold<int>(0, (sum, item) => sum + item.bytes.length);
  if (total + adding.bytes.length > maxComposerTotalBytes) {
    return 'Os anexos passariam de ${maxComposerTotalBytes ~/ (1024 * 1024)} MB. '
        'Envie em mensagens separadas.';
  }
  return null;
}

String attachmentMimeType(String name) {
  final lower = name.toLowerCase();
  const known = <String, String>{
    '.aac': 'audio/aac',
    '.csv': 'text/csv',
    '.gif': 'image/gif',
    '.jpeg': 'image/jpeg',
    '.jpg': 'image/jpeg',
    '.json': 'application/json',
    '.m4a': 'audio/mp4',
    '.md': 'text/markdown',
    '.mp3': 'audio/mpeg',
    '.ogg': 'audio/ogg',
    '.opus': 'audio/ogg',
    '.pdf': 'application/pdf',
    '.png': 'image/png',
    '.txt': 'text/plain',
    '.wav': 'audio/wav',
    '.webm': 'audio/webm',
    '.webp': 'image/webp',
    '.xml': 'application/xml',
    '.yaml': 'application/yaml',
    '.yml': 'application/yaml',
    '.zip': 'application/zip',
  };
  for (final entry in known.entries) {
    if (lower.endsWith(entry.key)) return entry.value;
  }
  return 'application/octet-stream';
}

String composeGatewayAttachmentInput(
  String caption,
  Iterable<ComposerAttachment> attachments,
) {
  final refs = attachments
      .map((item) => item.refText?.trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  final text = caption.trim();
  return [...refs, if (text.isNotEmpty) text].join('\n\n');
}
