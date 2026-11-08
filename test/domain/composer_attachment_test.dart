import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';

void main() {
  ComposerAttachment sized(String id, int bytes) => ComposerAttachment(
    id: id,
    name: '$id.bin',
    mimeType: 'application/octet-stream',
    bytes: Uint8List(bytes),
  );

  test('A87: teto de quantidade e de bytes somados', () {
    const mb = 1024 * 1024;
    expect(composerBudgetProblem(const []), isNull);
    expect(
      composerBudgetProblem([sized('a', 25 * mb)], adding: sized('b', 25 * mb)),
      isNull,
      reason: 'dois arquivos no limite individual cabem',
    );
    expect(
      composerBudgetProblem([
        sized('a', 25 * mb),
      ], adding: sized('b', 25 * mb + 1)),
      'Os anexos passariam de 50 MB. Envie em mensagens separadas.',
    );
    final nine = [for (var i = 0; i < 9; i++) sized('$i', 1)];
    expect(composerBudgetProblem(nine, adding: sized('x', 1)), isNull);
    final ten = [...nine, sized('9', 1)];
    expect(composerBudgetProblem(ten), 'Limite de 10 anexos por mensagem.');
    expect(
      composerBudgetProblem(ten, adding: sized('x', 1)),
      'Limite de 10 anexos por mensagem.',
    );
  });

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
