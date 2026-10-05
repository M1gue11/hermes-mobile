import '../models/composer_attachment.dart';

abstract interface class AttachmentSource {
  Future<ComposerAttachment?> pickFile();
  Future<bool> hasMicrophonePermission();
  Future<void> startRecording();
  Future<ComposerAttachment?> stopRecording();
  Future<void> cancelRecording();
  Future<void> discard(ComposerAttachment attachment);
  Future<void> dispose();
}
