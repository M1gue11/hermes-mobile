import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/attachment_envelope.dart';

/// A nota exata que `_build_document_context_note` monta para texto.
String notaDeTexto(String nome, String caminho) =>
    "[The user sent a text document: '$nome'. "
    'Its content has been included below. '
    'The file is also saved at: $caminho]';

/// A variante binária, que segue com mais frases depois do caminho.
String notaBinaria(String nome, String caminho) =>
    "[The user sent a document: '$nome'. It is saved at: $caminho. "
    "Its text is not inlined here (it's a binary format such as PDF or DOCX). "
    "To read it, extract the document's text yourself - for example with the "
    'terminal tool or the ocr-and-documents skill - before answering, instead '
    'of asking the user to paste the contents.]';

void main() {
  group('texto sem envelope', () {
    test('mensagem digitada não vira anexo', () {
      expect(parseAttachmentEnvelope('e aí, tudo bem?'), isNull);
    });

    test('texto que só começa com colchete continua sendo fala', () {
      expect(
        parseAttachmentEnvelope('[isso aqui é meu, não do runtime]'),
        isNull,
      );
    });
  });

  group('referencias do TUI gateway', () {
    test('separa arquivos da legenda', () {
      final envelope = parseAttachmentEnvelope(
        '@file:.hermes/desktop-attachments/relatorio.pdf\n\n'
        '@file:".hermes/desktop-attachments/foto da viagem.jpg"\n\n'
        'Veja os dois, por favor.',
      )!;

      expect(envelope.caption, 'Veja os dois, por favor.');
      expect(envelope.captionMayBeInContent, isFalse);
      expect(envelope.attachments, hasLength(2));
      expect(envelope.attachments.first.name, 'relatorio.pdf');
      expect(envelope.attachments.first.kind, AttachmentKind.document);
      expect(envelope.attachments.last.name, 'foto da viagem.jpg');
      expect(envelope.attachments.last.kind, AttachmentKind.image);
    });

    test('nao interpreta @file no meio de uma frase comum', () {
      expect(
        parseAttachmentEnvelope('use @file:exemplo.txt quando precisar'),
        isNull,
      );
    });
  });

  group('documento de texto embutido', () {
    const caminho =
        '/home/example/.hermes/cache/documents/ab12_99_transactions.csv';

    test('o envelope sai da bolha e o conteúdo vai para o anexo', () {
      final turno =
          '${notaDeTexto('transactions.csv', caminho)}\n\n'
          '[Content of transactions.csv]:\n'
          'data,valor\n2026-08-01,10.00';

      final envelope = parseAttachmentEnvelope(turno)!;
      expect(envelope.attachments, hasLength(1));
      final anexo = envelope.attachments.single;
      expect(anexo.kind, AttachmentKind.text);
      expect(anexo.name, 'transactions.csv');
      expect(anexo.path, caminho);
      expect(anexo.content, 'data,valor\n2026-08-01,10.00');
      expect(anexo.bytes, 27);
      expect(envelope.caption, isEmpty);
      // Sem legenda e sem cauda depois de linha em branco: não há o que avisar.
      expect(envelope.captionMayBeInContent, isFalse);
    });

    test('com o sinal das três quebras, a legenda vira fala', () {
      // Arquivo terminado em `\n` mais o `\n\n` da junção: três quebras.
      final turno =
          '${notaDeTexto('transactions.csv', caminho)}\n\n'
          '[Content of transactions.csv]:\n'
          'data,valor\n2026-08-01,10.00\n'
          '\n\n'
          'me explica esse extrato';

      final envelope = parseAttachmentEnvelope(turno)!;
      expect(envelope.caption, 'me explica esse extrato');
      expect(
        envelope.attachments.single.content,
        'data,valor\n2026-08-01,10.00',
      );
      expect(envelope.captionMayBeInContent, isFalse);
    });

    test('linha em branco interna não promove o fim do arquivo a fala', () {
      // Este é o caso que o A23 ensinou a temer: sem as três quebras, separar
      // pelo último parágrafo poria na boca da pessoa a última linha do arquivo.
      final turno =
          '${notaDeTexto('notas.md', caminho)}\n\n'
          '[Content of notas.md]:\n'
          '# título\n\ncorpo do arquivo\n\núltima linha do arquivo';

      final envelope = parseAttachmentEnvelope(turno)!;
      expect(envelope.caption, isEmpty);
      expect(
        envelope.attachments.single.content,
        '# título\n\ncorpo do arquivo\n\núltima linha do arquivo',
      );
      // Mas a tela pode dizer que talvez haja legenda ali dentro.
      expect(envelope.captionMayBeInContent, isTrue);
    });

    test('duas corridas de três quebras deixam de ser sinal', () {
      final turno =
          '[Content of notas.txt]:\n'
          'um\n\n\ndois\n\n\ntrês';

      final envelope = parseAttachmentEnvelope(turno)!;
      expect(envelope.caption, isEmpty);
      expect(envelope.attachments.single.content, 'um\n\n\ndois\n\n\ntrês');
    });

    test('conteúdo sem nota anterior ainda é anexo', () {
      final envelope = parseAttachmentEnvelope('[Content of a.txt]:\noi')!;
      expect(envelope.attachments.single.name, 'a.txt');
      expect(envelope.attachments.single.content, 'oi');
    });
  });

  group('documento binário e mídia', () {
    test('PDF vira anexo e a legenda depois da nota é fala segura', () {
      // Sem conteúdo embutido a junção é exata: a nota fecha em `]`.
      final turno =
          '${notaBinaria('contrato.pdf', '/root/.hermes/cache/x_1_contrato.pdf')}'
          '\n\nresume pra mim';

      final envelope = parseAttachmentEnvelope(turno)!;
      final anexo = envelope.attachments.single;
      expect(anexo.kind, AttachmentKind.document);
      expect(anexo.name, 'contrato.pdf');
      expect(anexo.path, '/root/.hermes/cache/x_1_contrato.pdf');
      expect(anexo.content, isNull);
      expect(envelope.caption, 'resume pra mim');
      expect(envelope.captionMayBeInContent, isFalse);
    });

    test('placeholder de mídia sem legenda não inventa fala', () {
      const turno =
          '[User sent an image: /cache/img/aa_7_foto.jpg]\n'
          '[User sent a file: /cache/files/bb_8_dados.bin]';

      final envelope = parseAttachmentEnvelope(turno)!;
      expect(envelope.attachments.map((a) => a.kind), [
        AttachmentKind.image,
        AttachmentKind.file,
      ]);
      expect(envelope.attachments.first.name, 'foto.jpg');
      expect(envelope.attachments.last.name, 'dados.bin');
      expect(envelope.caption, isEmpty);
    });

    test('o marcador de mensagem sem texto não vira legenda', () {
      const turno =
          '[User sent an image: /cache/img/aa_7_foto.jpg]\n\n'
          '(The user sent a message with no text content)';
      expect(parseAttachmentEnvelope(turno)!.caption, isEmpty);
    });

    test('mensagem de voz guarda a duração', () {
      const turno =
          '[The user sent a voice message: /cache/audio/cc_9_nota.ogg '
          '(duration: 0:12)]\n\ntranscreve';

      final envelope = parseAttachmentEnvelope(turno)!;
      final anexo = envelope.attachments.single;
      expect(anexo.kind, AttachmentKind.voice);
      expect(anexo.path, '/cache/audio/cc_9_nota.ogg');
      expect(anexo.note, '0:12');
      expect(envelope.caption, 'transcreve');
    });

    test('a descrição da visão fica no anexo, não na bolha', () {
      const turno =
          "[The user sent an image~ Here's what I can see:\n"
          'Um gráfico de barras com o gasto mensal.]\n'
          '[If you need a closer look, use vision_analyze with '
          'image_url: /cache/img/dd_3_grafico.png ~]\n\n'
          'que mês foi o pior?';

      final envelope = parseAttachmentEnvelope(turno)!;
      // O rodapé completa o mesmo anexo em vez de abrir um segundo.
      expect(envelope.attachments, hasLength(1));
      final anexo = envelope.attachments.single;
      expect(anexo.kind, AttachmentKind.image);
      expect(anexo.name, 'grafico.png');
      expect(anexo.note, contains('gráfico de barras'));
      expect(envelope.caption, 'que mês foi o pior?');
    });

    test('mais de um anexo aparece na ordem em que o servidor prefixou', () {
      final turno =
          '${notaBinaria('b.pdf', '/c/x_2_b.pdf')}\n\n'
          '${notaBinaria('a.pdf', '/c/x_1_a.pdf')}\n\n'
          'compara os dois';

      final envelope = parseAttachmentEnvelope(turno)!;
      expect(envelope.attachments.map((a) => a.name), ['b.pdf', 'a.pdf']);
      expect(envelope.caption, 'compara os dois');
    });
  });

  group('nome, tipo e tamanho', () {
    test('o nome sai do cache do jeito que o servidor calcula', () {
      expect(
        attachmentNameFromPath('/c/9f2a_1712_transactions_2026.csv'),
        'transactions_2026.csv',
      );
      // Menos de três pedaços: o basename inteiro.
      expect(attachmentNameFromPath('/c/foto.jpg'), 'foto.jpg');
    });

    test('acento sobrevive à higienização, como no servidor', () {
      expect(
        sanitizeAttachmentName('Relatório anual.csv'),
        'Relatório anual.csv',
      );
      expect(sanitizeAttachmentName('nota:fiscal?.pdf'), 'nota_fiscal_.pdf');
    });

    test('a etiqueta é a extensão, e o tipo quando não há', () {
      Attachment anexo(String nome, AttachmentKind kind) => (
        kind: kind,
        name: nome,
        path: null,
        note: null,
        content: null,
        bytes: null,
      );

      expect(
        attachmentTypeLabel(anexo('extrato.csv', AttachmentKind.text)),
        'CSV',
      );
      expect(
        attachmentTypeLabel(anexo('imagem', AttachmentKind.image)),
        'IMAGEM',
      );
    });

    test('o tamanho é legível e em português', () {
      expect(attachmentSizeLabel(512), '512 B');
      expect(attachmentSizeLabel(2048), '2 KB');
      expect(attachmentSizeLabel(4300), '4,2 KB');
      expect(attachmentSizeLabel(3 * 1024 * 1024), '3 MB');
    });
  });
}
