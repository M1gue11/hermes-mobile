import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/platform/device_attachment_source.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';

void main() {
  test(
    'A78: oversized selection refuses that file and keeps the remaining files',
    () async {
      final source = DeviceAttachmentSource(
        filePicker: () async => [
          _File('grande.pdf', size: maxComposerAttachmentBytes + 1),
          _File('pequeno.pdf'),
          _File('outro.txt'),
        ],
      );
      final picked = await source.pickFiles(
        availableSlots: 10,
        availableBytes: maxComposerTotalBytes,
      );
      expect(picked.attachments.map((e) => e.name), [
        'pequeno.pdf',
        'outro.txt',
      ]);
      expect(picked.errors.single, contains('grande.pdf'));
      expect(picked.errors.single, contains('25 MB'));
    },
  );

  test(
    'A78: remaining count refuses named files before reading bytes',
    () async {
      final excess = _File('excedente.txt');
      final source = DeviceAttachmentSource(
        filePicker: () async => [_File('um.txt'), excess],
      );
      final picked = await source.pickFiles(
        availableSlots: 1,
        availableBytes: maxComposerTotalBytes,
      );
      expect(picked.attachments, hasLength(1));
      expect(picked.errors.single, contains('excedente.txt'));
      expect(excess.reads, 0);
    },
  );

  test(
    'A78: over-budget file does not prevent a smaller file from fitting',
    () async {
      final excess = _File('maior.txt', size: 4);
      final source = DeviceAttachmentSource(
        filePicker: () async => [excess, _File('cabe.txt')],
      );
      final picked = await source.pickFiles(
        availableSlots: 10,
        availableBytes: 3,
      );
      expect(picked.attachments.single.name, 'cabe.txt');
      expect(picked.errors.single, contains('maior.txt'));
      expect(excess.reads, 0);
    },
  );

  test(
    'A78: growing file is stopped while reading and the next one still fits',
    () async {
      final source = DeviceAttachmentSource(
        filePicker: () async => [
          _File('cresceu.txt', actualSize: 7),
          _File('cabe.txt'),
        ],
      );
      final picked = await source.pickFiles(
        availableSlots: 10,
        availableBytes: 5,
      );
      expect(picked.attachments.single.name, 'cabe.txt');
      expect(picked.errors.single, contains('cresceu.txt'));
    },
  );
}

class _File extends XFile {
  _File(this.fileName, {this.size = 1, this.actualSize = 1})
    : super('/synthetic/$fileName');
  final String fileName;
  final int size;
  final int actualSize;
  int reads = 0;
  @override
  String get name => fileName;
  @override
  Future<int> length() async => size;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) async* {
    reads++;
    yield Uint8List(actualSize);
  }
}
