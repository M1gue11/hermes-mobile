import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:record/record.dart';

import '../../domain/models/composer_attachment.dart';
import '../../domain/repositories/attachment_source.dart';
import '../../domain/repositories/gateway_repository.dart';

class DeviceAttachmentSource implements AttachmentSource {
  DeviceAttachmentSource({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  final Set<String> _ownedRecordings = {};
  String? _recordingPath;
  var _seed = 0;

  @override
  Future<ComposerAttachment?> pickFile() async {
    final file = await openFile();
    if (file == null) return null;
    if (await file.length() > maxComposerAttachmentBytes) {
      throw const GatewayOperationException(
        'O arquivo excede o limite móvel de 25 MB.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxComposerAttachmentBytes) {
      throw const GatewayOperationException(
        'O arquivo excede o limite móvel de 25 MB.',
      );
    }
    return ComposerAttachment(
      id: _id(),
      name: file.name,
      mimeType: attachmentMimeType(file.name),
      bytes: bytes,
      localPath: file.path,
    );
  }

  @override
  Future<bool> hasMicrophonePermission() => _recorder.hasPermission();

  @override
  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw const GatewayOperationException(
        'Permita o acesso ao microfone para gravar uma mensagem.',
      );
    }
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'hermes-voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    _recordingPath = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 96000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: path,
    );
  }

  @override
  Future<ComposerAttachment?> stopRecording() async {
    final path = await _recorder.stop() ?? _recordingPath;
    _recordingPath = null;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    if (await file.length() > maxComposerAttachmentBytes) {
      await file.delete();
      throw const GatewayOperationException(
        'A gravação excedeu o limite de 25 MB.',
      );
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      await file.delete();
      return null;
    }
    if (bytes.length > maxComposerAttachmentBytes) {
      await file.delete();
      throw const GatewayOperationException(
        'A gravação excedeu o limite de 25 MB.',
      );
    }
    _ownedRecordings.add(path);
    return ComposerAttachment(
      id: _id(),
      name: 'mensagem-de-voz.m4a',
      mimeType: 'audio/mp4',
      bytes: bytes,
      kind: ComposerAttachmentKind.audio,
      localPath: path,
    );
  }

  @override
  Future<void> cancelRecording() async {
    await _recorder.cancel();
    _recordingPath = null;
  }

  @override
  Future<void> discard(ComposerAttachment attachment) async {
    final path = attachment.localPath;
    if (attachment.kind != ComposerAttachmentKind.audio ||
        path == null ||
        !_ownedRecordings.remove(path)) {
      return;
    }
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
    for (final path in _ownedRecordings.toList(growable: false)) {
      final file = File(path);
      if (await file.exists()) await file.delete();
      _ownedRecordings.remove(path);
    }
  }

  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${++_seed}';
}
