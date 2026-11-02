import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/audio/speech_player.dart';
import '../../data/gateway_repository_provider.dart';
import '../../domain/models/plain_text.dart';

enum ReadAloudPhase { synthesizing, playing }

typedef ReadAloudState = ({String messageId, ReadAloudPhase phase});

/// Teto do texto mandado ao TTS. Uma resposta longa levaria minutos para
/// sintetizar e para ouvir; o começo é o que se quer de ouvido.
const readAloudMaxChars = 4000;

/// Ouvir uma resposta do agente (A102): uma por vez, para o app inteiro.
///
/// Tocar a mesma resposta de novo para. Tocar outra para a atual e começa a
/// nova; uma síntese que chegar depois disso é descartada, em vez de tocar
/// por cima da escolha mais recente.
final readAloudProvider = NotifierProvider<ReadAloud, ReadAloudState?>(
  ReadAloud.new,
);

class ReadAloud extends Notifier<ReadAloudState?> {
  var _pedido = 0;

  @override
  ReadAloudState? build() {
    final fim = ref.watch(speechPlayerProvider).completed.listen((_) {
      if (state?.phase == ReadAloudPhase.playing) state = null;
    });
    ref.onDispose(fim.cancel);
    return null;
  }

  Future<void> toggle(String messageId, String markdown) async {
    final player = ref.read(speechPlayerProvider);
    final pedido = ++_pedido;
    if (state?.messageId == messageId) {
      state = null;
      await player.stop();
      return;
    }
    // O retorno do toque vem antes de qualquer espera.
    state = (messageId: messageId, phase: ReadAloudPhase.synthesizing);
    await player.stop();
    try {
      final audio = await ref
          .read(gatewayRepositoryProvider)
          .speak(speakableText(markdown));
      if (pedido != _pedido) return;
      await player.play(audio.bytes, mimeType: audio.mimeType);
      if (pedido != _pedido) return;
      state = (messageId: messageId, phase: ReadAloudPhase.playing);
    } catch (_) {
      if (pedido == _pedido) state = null;
      rethrow;
    }
  }

  Future<void> stop() async {
    _pedido++;
    state = null;
    await ref.read(speechPlayerProvider).stop();
  }
}

/// O que vai para o TTS: o texto de leitura, sem marcação nem entregas de
/// arquivo, cortado no fim de frase mais próximo do teto.
String speakableText(String markdown) {
  final texto = markdownToPlainText(
    markdown,
  ).replaceAll(RegExp(r'MEDIA:\s*\S+'), '').trim();
  if (texto.length <= readAloudMaxChars) return texto;
  final corte = texto.substring(0, readAloudMaxChars);
  final fim = corte.lastIndexOf(RegExp(r'[.!?…]\s'));
  return fim > readAloudMaxChars ~/ 2 ? corte.substring(0, fim + 1) : corte;
}
