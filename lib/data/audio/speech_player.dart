import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/speech_player.dart';

/// Player do aparelho, um só para o app inteiro.
final speechPlayerProvider = Provider<SpeechPlayer>((ref) {
  final player = AudioplayersSpeechPlayer();
  ref.onDispose(player.dispose);
  return player;
});

class AudioplayersSpeechPlayer implements SpeechPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play(Uint8List bytes, {required String mimeType}) async {
    await _player.stop();
    await _player.play(BytesSource(bytes, mimeType: mimeType));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get completed => _player.onPlayerComplete;

  Future<void> dispose() => _player.dispose();
}
