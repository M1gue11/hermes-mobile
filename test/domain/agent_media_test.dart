import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/agent_media.dart';

void main() {
  test('arquivo isolado na linha conserva pastas e nomes com espaços', () {
    const path = '/srv/Projeto exemplo/2026-11-09 - Orçamento final.md';
    expect(mediaPathsIn('Pronto:\n\nMEDIA:$path\n\nDepois.'), [path]);
  });

  test('arquivo inline entre aspas conserva espaços sem engolir a prosa', () {
    expect(
      mediaPathsIn(
        'Veja MEDIA:"/srv/arquivo final.pdf" e depois '
        "MEDIA:'/srv/outro arquivo.txt'.",
      ),
      ['/srv/arquivo final.pdf', '/srv/outro arquivo.txt'],
    );
  });

  test('reconhece caminhos absolutos POSIX, home e Windows', () {
    expect(
      mediaPathsIn(
        'Pronto: MEDIA:/root/.hermes/images/a.png e '
        r'MEDIA: ~/shots/b.jpg, além de MEDIA:C:\Users\x\c.webp',
      ),
      ['/root/.hermes/images/a.png', '~/shots/b.jpg', r'C:\Users\x\c.webp'],
    );
  });

  test('deixa de fora pontuação, aspas e ênfase coladas ao fim', () {
    expect(mediaPathsIn('**MEDIA:/tmp/a.png**.'), ['/tmp/a.png']);
    expect(mediaPathsIn('(veja MEDIA:/tmp/computer_use_1.png)'), [
      '/tmp/computer_use_1.png',
    ]);
    expect(mediaPathsIn('`MEDIA:/tmp/a.png`'), ['/tmp/a.png']);
  });

  test('não confunde menção à diretiva com entrega', () {
    expect(mediaPathsIn('use MEDIA:<path> para enviar'), isEmpty);
    expect(mediaPathsIn('MEDIA:relativo/a.png'), isEmpty);
  });

  test('nome e tipo desenhável', () {
    expect(mediaFileName('/root/.hermes/images/a.png'), 'a.png');
    expect(mediaFileName(r'C:\x\y\relatorio.pdf'), 'relatorio.pdf');
    expect(isInlineImagePath('/a/B.JPEG'), isTrue);
    expect(isInlineImagePath('/a/diagrama.svg'), isFalse);
    expect(isInlineImagePath('/a/relatorio.pdf'), isFalse);
    expect(isInlineImagePath('/a/.png'), isFalse);
  });
}
