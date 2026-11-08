import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'push_notice.freezed.dart';

/// Evento do plugin `mobile-push` (ver `server/mobile-push/README.md`).
enum PushNoticeKind {
  turnCompleted('turn.completed'),
  turnFailed('turn.failed'),
  turnInterrupted('turn.interrupted'),
  inputRequested('input.requested'),
  inputResolved('input.resolved'),
  test('test');

  const PushNoticeKind(this.wire);

  final String wire;

  static PushNoticeKind? fromWire(Object? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// O que o agente espera da pessoa em [PushNoticeKind.inputRequested].
enum PushInputKind { approval, clarify, sudo }

/// Envelope mínimo de um push: diz o que aconteceu e em qual conversa, nunca o
/// conteúdo. O texto só aparece depois de abrir a conversa autenticada.
@freezed
abstract class PushNotice with _$PushNotice {
  const PushNotice._();

  const factory PushNotice({
    required PushNoticeKind kind,
    @Default('') String sessionId,
    String? title,
    PushInputKind? input,
    String? requestId,
    DateTime? sentAt,
  }) = _PushNotice;

  static const supportedVersion = 1;

  /// `null` para versão desconhecida, tipo desconhecido ou corpo malformado:
  /// um push que o app não entende não pode virar aviso inventado.
  static PushNotice? tryParse(List<int> bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final json = decoded;
    if (json['v'] != supportedVersion) return null;
    final kind = PushNoticeKind.fromWire(json['kind']);
    if (kind == null) return null;
    final sessionId = _text(json['session_id']) ?? '';
    final needsSession = kind != PushNoticeKind.test;
    if (needsSession && sessionId.isEmpty) return null;
    final requestId = _text(json['request_id']);
    final input = PushInputKind.values
        .where((value) => value.name == json['input'])
        .firstOrNull;
    if (kind == PushNoticeKind.inputRequested &&
        (input == null || requestId == null)) {
      return null;
    }
    if (kind == PushNoticeKind.inputResolved && requestId == null) return null;
    final ts = json['ts'];
    return PushNotice(
      kind: kind,
      sessionId: sessionId,
      title: _text(json['title']),
      input: input,
      requestId: requestId,
      sentAt: ts is int
          ? DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true)
          : null,
    );
  }

  /// Chave do aviso no aparelho. Turnos da mesma conversa se substituem; cada
  /// pedido de aprovação tem a sua, para o `input.resolved` apagar só ele.
  String get slot => switch (kind) {
    PushNoticeKind.inputRequested ||
    PushNoticeKind.inputResolved => 'input:$requestId',
    PushNoticeKind.test => 'test',
    _ => 'turn:$sessionId',
  };

  bool get clearsSlot => kind == PushNoticeKind.inputResolved;

  bool get needsAttention => kind == PushNoticeKind.inputRequested;
}

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Id inteiro estável para a [PushNotice.slot] (FNV-1a de 31 bits).
///
/// `String.hashCode` não serve: o valor pode mudar entre execuções, e o
/// isolate de background precisa substituir o aviso que o app mostrou antes.
int noticeSlotId(String slot) {
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode(slot)) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}
