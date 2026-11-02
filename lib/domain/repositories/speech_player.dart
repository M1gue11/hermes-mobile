import 'dart:typed_data';

/// Toca um áudio curto já sintetizado (A102). Um por vez: tocar outro
/// interrompe o anterior.
abstract interface class SpeechPlayer {
  Future<void> play(Uint8List bytes, {required String mimeType});

  Future<void> stop();

  /// Emite quando o áudio em curso chega ao fim sozinho.
  Stream<void> get completed;
}
