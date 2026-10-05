import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';

void main() {
  test('compõe referências antes da legenda', () {
    final one = ComposerAttachment(
      id: '1',
      name: 'um.pdf',
      mimeType: 'application/pdf',
      bytes: Uint8List(0),
      refText: '@file:um.pdf',
    );
    final two = ComposerAttachment(
      id: '2',
      name: 'dois.csv',
      mimeType: 'text/csv',
      bytes: Uint8List(0),
      refText: '@file:dois.csv',
    );

    expect(
      composeGatewayAttachmentInput('analise os dois', [one, two]),
      '@file:um.pdf\n\n@file:dois.csv\n\nanalise os dois',
    );
  });

  test('mime desconhecido é binário genérico', () {
    expect(attachmentMimeType('arquivo.xyz'), 'application/octet-stream');
    expect(attachmentMimeType('VOZ.M4A'), 'audio/mp4');
  });
}
