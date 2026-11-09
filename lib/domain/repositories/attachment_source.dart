import '../models/composer_attachment.dart';

typedef AttachmentSelection = ({
  List<ComposerAttachment> attachments,
  List<String> errors,
});

abstract interface class AttachmentSource {
  Future<AttachmentSelection> pickFiles({
    required int availableSlots,
    required int availableBytes,
  });
  Future<bool> hasMicrophonePermission();
  Future<void> startRecording();
  Future<ComposerAttachment?> stopRecording();
  Future<void> cancelRecording();
  Future<void> discard(ComposerAttachment attachment);
  Future<void> dispose();
}
