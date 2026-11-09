import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:record/record.dart';

import '../../domain/models/composer_attachment.dart';
import '../../domain/repositories/attachment_source.dart';
import '../../domain/repositories/gateway_repository.dart';

class DeviceAttachmentSource implements AttachmentSource {
  DeviceAttachmentSource({
    AudioRecorder? recorder,
    Future<List<XFile>> Function()? filePicker,
  }) : _audioRecorder = recorder,
       _filePicker = filePicker ?? openFiles;

  AudioRecorder? _audioRecorder;
  AudioRecorder get _recorder => _audioRecorder ??= AudioRecorder();
  final Future<List<XFile>> Function() _filePicker;
  final Set<String> _ownedRecordings = {};
  String? _recordingPath;
  var _seed = 0;

  @override
  Future<AttachmentSelection> pickFiles({
    required int availableSlots,
    required int availableBytes,
  }) async {
    final files = await _filePicker();
    final attachments = <ComposerAttachment>[];
    final errors = <String>[];
    var remaining = availableBytes;
    for (final file in files) {
      try {
        if (attachments.length >= availableSlots) {
          errors.add('${file.name}: limite de 10 anexos por mensagem.');
          continue;
        }
        final size = await file.length();
        if (size > maxComposerAttachmentBytes) {
          errors.add('${file.name}: excede o limite de 25 MB por arquivo.');
          continue;
        }
        if (size > remaining) {
          errors.add('${file.name}: os anexos passariam de 50 MB.');
          continue;
        }
        // Limitar também durante a leitura: um arquivo pode crescer depois
        // do stat. O lote nunca acumula mais bytes do que o composer comporta.
        final builder = BytesBuilder(copy: false);
        var tooLarge = false;
        await for (final chunk in file.openRead()) {
          if (builder.length + chunk.length > maxComposerAttachmentBytes ||
              builder.length + chunk.length > remaining) {
            tooLarge = true;
            break;
          }
          builder.add(chunk);
        }
        if (tooLarge) {
          errors.add('${file.name}: excede o limite de tamanho dos anexos.');
          continue;
        }
        final bytes = builder.takeBytes();
        remaining -= bytes.length;
        attachments.add(
          ComposerAttachment(
            id: _id(),
            name: file.name,
            mimeType: attachmentMimeType(file.name),
            bytes: bytes,
            localPath: file.path,
          ),
        );
      } catch (_) {
        errors.add('${file.name}: não foi possível abrir este arquivo.');
      }
    }
    return (attachments: attachments, errors: errors);
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
    await _audioRecorder?.dispose();
    for (final path in _ownedRecordings.toList(growable: false)) {
      final file = File(path);
      if (await file.exists()) await file.delete();
      _ownedRecordings.remove(path);
    }
  }

  String _id() => '${DateTime.now().microsecondsSinceEpoch}-${++_seed}';
}
