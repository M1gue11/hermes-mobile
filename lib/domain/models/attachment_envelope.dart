/// Reconhece o envelope que o runtime monta quando a pessoa manda um anexo.
///
/// **O turno é fala de verdade**, ao contrário do andaime do A23: a pessoa de
/// fato mandou o arquivo e o servidor não classifica esse turno como sintético.
/// O que está errado é a apresentação. Hoje a bolha `VOCÊ` mostra
/// `[The user sent a text document: 'transactions.csv'. ...]` seguido do CSV inteiro,
/// em itálico, como se tivesse sido digitado.
///
/// **Medido na versão `0.19.0`**, e o turno é montado em duas etapas, por código
/// diferente:
///
/// 1. O adaptador da plataforma embute o arquivo em `event.text`, com
///    `injection = f"[Content of {display_name}]:\n{text_content}"`, teto de
///    100 KB, só para extensão/MIME de texto. Os adaptadores usam a mesma
///    string (`plugins/platforms/{telegram,slack,discord}/adapter.py`). A
///    legenda digitada é concatenada **depois**: `f"{injection}\n\n{event.text}"`.
/// 2. `gateway/run.py:12620` prefixa a nota de contexto, de
///    `_build_document_context_note` (`run.py:2478`). Com mais de um anexo, cada
///    nota é prefixada por vez, então elas saem em ordem inversa. Imagem, áudio
///    e vídeo têm notas próprias, e `_build_media_placeholder` (`run.py:2458`)
///    cobre o caso de mídia sem legenda.
///
/// Resultado no banco:
///
/// ```
/// [The user sent a text document: 'N'. ... saved at: P]
///
/// [Content of N]:
/// <bytes do arquivo>
///
/// <legenda digitada, se houver>
/// ```
///
/// **A separação da legenda não é segura em todo caso, e isso é decisão de
/// produto, não de código.** O corpo do arquivo não tem terminador: o adaptador
/// só concatena `\n\n` antes da legenda. Um arquivo com linha em branco interna
/// produz exatamente a mesma sequência. Ver [_separarLegenda].
library;

import 'dart:convert';

/// O que o runtime disse que veio anexado.
enum AttachmentKind {
  text('documento de texto', 'TEXTO'),
  document('documento', 'DOCUMENTO'),
  image('imagem', 'IMAGEM'),
  audio('áudio', 'ÁUDIO'),
  video('vídeo', 'VÍDEO'),
  voice('mensagem de voz', 'VOZ'),
  file('arquivo', 'ARQUIVO');

  const AttachmentKind(this.label, this.tag);

  /// Como se fala dele numa frase.
  final String label;

  /// Etiqueta curta do card, quando o nome não tem extensão que sirva.
  final String tag;
}

/// Um anexo anunciado pelo runtime dentro do turno do usuário.
///
/// [content] só existe para documento de texto, que é o único caso em que o
/// adaptador embute os bytes. [bytes] é o tamanho **do que veio embutido**, não
/// o do arquivo original: acima de 100 KB o adaptador não embute nada, e supor
/// tamanho a partir do que não temos seria inventar número.
typedef Attachment = ({
  AttachmentKind kind,
  String name,
  String? path,
  String? note,
  String? content,
  int? bytes,
});

/// O turno do usuário depois de separado o que é máquina do que é fala.
///
/// [captionMayBeInContent] é o ponto sensível: quando ele é `true`, uma legenda
/// digitada **pode** estar no fim de [Attachment.content] e a tela não a mostra
/// como fala. Ver [_separarLegenda] para o porquê.
typedef AttachmentEnvelope = ({
  List<Attachment> attachments,
  String caption,
  bool captionMayBeInContent,
});

/// Marcador que os adaptadores usam quando a mensagem só tem mídia.
const _semTexto = '(The user sent a message with no text content)';

const _conteudo = '[Content of ';

/// As notas que o runtime prefixa ao turno, copiadas da fonte `0.19.0`.
///
/// A ordem importa: prefixo mais específico primeiro, porque a busca para no
/// primeiro que casar.
const _tabela = <_Nota>[
  _Nota(
    "[The user sent a text document: '",
    AttachmentKind.text,
    marcador: 'saved at: ',
  ),
  _Nota(
    "[The user sent a document: '",
    AttachmentKind.document,
    marcador: 'saved at: ',
  ),
  _Nota(
    "[The user sent an audio file attachment: '",
    AttachmentKind.audio,
    marcador: 'saved at: ',
  ),
  _Nota(
    "[The user sent a video attachment: '",
    AttachmentKind.video,
    marcador: 'saved at: ',
  ),
  _Nota('[The user sent a voice message: ', AttachmentKind.voice),
  // Descrição da análise automática de imagem. A nota inteira é o texto.
  _Nota(
    "[The user sent an image~ Here's what I can see:",
    AttachmentKind.image,
    descricao: true,
  ),
  _Nota(
    '[The user sent an image but ',
    AttachmentKind.image,
    marcador: 'image_url: ',
    descricao: true,
  ),
  // Não é anexo novo: é o rodapé da nota de visão, e traz o caminho dela.
  _Nota(
    '[If you need a closer look, use vision_analyze with image_url: ',
    AttachmentKind.image,
    complemento: true,
  ),
  _Nota('[User sent an image: ', AttachmentKind.image),
  _Nota('[User sent audio: ', AttachmentKind.audio),
  _Nota('[User sent a video: ', AttachmentKind.video),
  _Nota('[User sent a file: ', AttachmentKind.file),
];

class _Nota {
  const _Nota(
    this.prefix,
    this.kind, {
    this.marcador,
    this.complemento = false,
    this.descricao = false,
  });

  final String prefix;
  final AttachmentKind kind;

  /// Onde o caminho começa dentro da nota, quando não vem logo após o prefixo.
  final String? marcador;

  /// Completa o anexo anterior em vez de abrir um novo.
  final bool complemento;

  /// O corpo da nota é texto para ler, não só metadado.
  final bool descricao;

  /// O nome do arquivo vem entre aspas simples logo após o prefixo.
  bool get nomeEntreAspas => prefix.endsWith("'");
}

/// Separa o envelope de máquina da fala da pessoa.
///
/// Devolve `null` quando o texto não tem envelope nenhum, que é o caso de toda
/// mensagem digitada no app.
AttachmentEnvelope? parseAttachmentEnvelope(String texto) {
  final gatewayFiles = _parseGatewayFileRefs(texto);
  if (gatewayFiles != null) return gatewayFiles;

  var resto = texto.trimLeft();
  final anexos = <Attachment>[];
  var achouNota = false;

  while (resto.startsWith('[')) {
    final nota = _casar(resto);
    if (nota == null) break;
    achouNota = true;
    final fim = _fimDaNota(resto);
    _absorver(anexos, nota, resto.substring(0, fim));
    resto = _pularSeparador(resto.substring(fim));
  }

  String? embutido;
  String? corpo;
  if (resto.startsWith(_conteudo)) {
    final fecha = resto.indexOf(']:');
    if (fecha > 0) {
      embutido = resto.substring(_conteudo.length, fecha);
      corpo = resto.substring(fecha + 2);
      if (corpo.startsWith('\n')) corpo = corpo.substring(1);
      resto = '';
    }
  }

  if (!achouNota && corpo == null) return null;
  // Reconhecemos alguma nota mas não sobrou anexo nenhum: é o rodapé da análise
  // de imagem chegando solto, sem a nota que ele completa. Sem card para pendurar
  // o texto, mostrar a bolha crua é melhor do que mostrar uma bolha vazia.
  if (anexos.isEmpty && corpo == null) return null;

  var legenda = '';
  var talvezNoConteudo = false;
  if (corpo != null) {
    final separado = _separarLegenda(corpo);
    corpo = separado.conteudo;
    legenda = separado.legenda;
    talvezNoConteudo = separado.incerto;
    _guardarConteudo(anexos, embutido ?? '', corpo);
  } else {
    legenda = resto.trim();
  }

  if (legenda == _semTexto) legenda = '';
  // Legenda que começa em colchete é quase certamente nota que o casamento não
  // reconheceu, e não fala. Vai para o card, atrás do toque, em vez de virar
  // texto atribuído a quem escreveu.
  if (legenda.startsWith('[') && anexos.isNotEmpty) {
    _anotar(anexos, legenda);
    legenda = '';
  }

  return (
    attachments: List.unmodifiable(anexos),
    caption: legenda,
    captionMayBeInContent: talvezNoConteudo,
  );
}

/// Reconhece as referencias retornadas por `file.attach` do TUI gateway.
///
/// O cliente envia cada referencia em um paragrafo antes da legenda. Aceitamos
/// somente referencias no inicio do turno para que uma frase comum contendo
/// `@file:` continue sendo exibida exatamente como foi escrita.
AttachmentEnvelope? _parseGatewayFileRefs(String texto) {
  var resto = texto.trimLeft();
  final anexos = <Attachment>[];

  while (resto.startsWith('@file:')) {
    final fimDaLinha = resto.indexOf(RegExp(r'[\r\n]'));
    final linha = fimDaLinha < 0 ? resto : resto.substring(0, fimDaLinha);
    final caminho = _unquoteGatewayPath(linha.substring('@file:'.length));
    if (caminho.isEmpty) break;

    anexos.add((
      kind: _gatewayAttachmentKind(caminho),
      name: attachmentNameFromPath(caminho),
      path: caminho,
      note: null,
      content: null,
      bytes: null,
    ));

    if (fimDaLinha < 0) {
      resto = '';
      break;
    }
    resto = _pularSeparador(resto.substring(fimDaLinha));
  }

  if (anexos.isEmpty) return null;
  return (
    attachments: List.unmodifiable(anexos),
    caption: resto.trim(),
    captionMayBeInContent: false,
  );
}

String _unquoteGatewayPath(String raw) {
  final path = raw.trim();
  if (path.length < 2) return path;
  final first = path[0];
  final last = path[path.length - 1];
  if ((first == '"' && last == '"') ||
      (first == "'" && last == "'") ||
      (first == '`' && last == '`')) {
    return path.substring(1, path.length - 1);
  }
  return path;
}

AttachmentKind _gatewayAttachmentKind(String path) {
  final dot = path.lastIndexOf('.');
  final extension = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
  if (const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic'}.contains(extension)) {
    return AttachmentKind.image;
  }
  if (const {
    'aac',
    'm4a',
    'mp3',
    'ogg',
    'opus',
    'wav',
    'flac',
  }.contains(extension)) {
    return AttachmentKind.audio;
  }
  if (const {'mp4', 'mov', 'mkv', 'webm', 'avi'}.contains(extension)) {
    return AttachmentKind.video;
  }
  if (extension == 'pdf') return AttachmentKind.document;
  if (const {
    'csv',
    'json',
    'log',
    'md',
    'txt',
    'xml',
    'yaml',
    'yml',
  }.contains(extension)) {
    return AttachmentKind.text;
  }
  return AttachmentKind.file;
}

_Nota? _casar(String resto) {
  for (final nota in _tabela) {
    if (resto.startsWith(nota.prefix)) return nota;
  }
  return null;
}

/// Onde a nota termina.
///
/// O fechamento é o primeiro `]` que encerra a linha ou o texto. Não serve o
/// primeiro `]` qualquer: a descrição da análise de imagem é multilinha e pode
/// conter colchete no meio.
int _fimDaNota(String resto) {
  var busca = resto.indexOf(']');
  while (busca >= 0) {
    final proximo = busca + 1;
    if (proximo == resto.length || resto[proximo] == '\n') return proximo;
    busca = resto.indexOf(']', proximo);
  }
  return resto.length;
}

String _pularSeparador(String resto) {
  var i = 0;
  while (i < resto.length && (resto[i] == '\n' || resto[i] == '\r')) {
    i++;
  }
  return resto.substring(i);
}

void _absorver(List<Attachment> anexos, _Nota nota, String bruto) {
  final corpo = bruto.substring(nota.prefix.length);

  if (nota.complemento && anexos.isNotEmpty) {
    final ultimo = anexos.last;
    if (ultimo.path == null) {
      final caminho = _limparCaminho(corpo);
      anexos[anexos.length - 1] = (
        kind: ultimo.kind,
        name: attachmentNameFromPath(caminho),
        path: caminho,
        note: ultimo.note,
        content: ultimo.content,
        bytes: ultimo.bytes,
      );
    }
    return;
  }

  String? nome;
  var depoisDoNome = corpo;
  if (nota.nomeEntreAspas) {
    final fecha = corpo.indexOf("'");
    if (fecha >= 0) {
      nome = sanitizeAttachmentName(corpo.substring(0, fecha));
      depoisDoNome = corpo.substring(fecha + 1);
    }
  }

  String? caminho;
  final marcador = nota.marcador;
  if (marcador != null) {
    final onde = depoisDoNome.indexOf(marcador);
    if (onde >= 0) {
      caminho = _limparCaminho(depoisDoNome.substring(onde + marcador.length));
    }
  } else if (!nota.descricao) {
    caminho = _limparCaminho(corpo);
  }

  String? extra;
  if (nota.descricao) {
    extra = _limparNota(corpo);
  } else if (nota.kind == AttachmentKind.voice) {
    extra = _duracao(corpo);
  }

  anexos.add((
    kind: nota.kind,
    name:
        nome ??
        (caminho == null || caminho.isEmpty
            ? nota.kind.label
            : attachmentNameFromPath(caminho)),
    path: caminho == null || caminho.isEmpty ? null : caminho,
    note: extra == null || extra.isEmpty ? null : extra,
    content: null,
    bytes: null,
  ));
}

/// Pendura o conteúdo embutido no anexo a que ele pertence.
void _guardarConteudo(List<Attachment> anexos, String nome, String conteudo) {
  final limpo = sanitizeAttachmentName(nome.trim());
  var alvo = anexos.indexWhere((a) => a.name == limpo);
  if (alvo < 0) alvo = anexos.indexWhere((a) => a.kind == AttachmentKind.text);
  final tamanho = utf8.encode(conteudo).length;

  if (alvo < 0) {
    // Conteúdo embutido sem nota correspondente ainda é um anexo real.
    anexos.add((
      kind: AttachmentKind.text,
      name: limpo.isEmpty ? AttachmentKind.text.label : limpo,
      path: null,
      note: null,
      content: conteudo,
      bytes: tamanho,
    ));
    return;
  }

  final atual = anexos[alvo];
  anexos[alvo] = (
    kind: atual.kind,
    name: atual.name,
    path: atual.path,
    note: atual.note,
    content: conteudo,
    bytes: tamanho,
  );
}

void _anotar(List<Attachment> anexos, String texto) {
  final ultimo = anexos.last;
  anexos[anexos.length - 1] = (
    kind: ultimo.kind,
    name: ultimo.name,
    path: ultimo.path,
    note: ultimo.note == null ? texto : '${ultimo.note}\n$texto',
    content: ultimo.content,
    bytes: ultimo.bytes,
  );
}

typedef _Corte = ({String conteudo, String legenda, bool incerto});

/// Onde o arquivo acaba e a fala começa.
///
/// **Decidido pelo usuário em 2026-07-27: separar só quando for seguro.** O
/// adaptador junta legenda ao conteúdo com `\n\n` e o arquivo não tem
/// terminador, então sobram dois erros possíveis, de naturezas diferentes:
///
/// - Nunca separar esconde fala real, jogando a legenda para dentro do conteúdo.
/// - Separar pelo último parágrafo promove a última linha do arquivo a fala da
///   pessoa quando não havia legenda. **Inventa fala**, que é exatamente o
///   defeito que o A23 corrigiu.
///
/// Escolhido errar mostrando de menos. O sinal usado é o único que distingue os
/// dois casos: arquivo terminado em `\n` mais o `\n\n` da junção dão **três**
/// quebras seguidas, contra as duas de uma linha em branco interna.
///
/// Sobre isso vale ainda a exigência de que a corrida de três quebras seja
/// **única** no corpo. Um arquivo com duas linhas em branco no meio produz o
/// mesmo sinal, e aí ele deixa de ser sinal: com mais de uma ocorrência não dá
/// para saber qual é a junção, então nenhuma é.
_Corte _separarLegenda(String corpo) {
  final quebras = RegExp(r'\n{3,}').allMatches(corpo).toList();
  if (quebras.length == 1) {
    final cauda = corpo.substring(quebras.first.end).trim();
    if (cauda.isNotEmpty) {
      return (
        conteudo: corpo.substring(0, quebras.first.start),
        legenda: cauda,
        incerto: false,
      );
    }
  }

  // Sem o sinal seguro: a legenda, se existir, ficou dentro do conteúdo. Só
  // dizemos isso quando há mesmo algo depois da última linha em branco; um
  // arquivo que termina em quebra não tem legenda escondida nenhuma.
  final ultimo = corpo.lastIndexOf('\n\n');
  final cauda = ultimo < 0 ? '' : corpo.substring(ultimo + 2).trim();
  return (conteudo: corpo, legenda: '', incerto: cauda.isNotEmpty);
}

String _limparCaminho(String bruto) {
  var valor = bruto.trim();
  if (valor.endsWith(']')) valor = valor.substring(0, valor.length - 1).trim();
  if (valor.endsWith('~')) valor = valor.substring(0, valor.length - 1).trim();
  final duracao = valor.indexOf(' (duration: ');
  if (duracao >= 0) valor = valor.substring(0, duracao);
  // A nota de documento binário continua com mais frases depois do caminho.
  final frase = valor.indexOf('. ');
  if (frase >= 0) valor = valor.substring(0, frase);
  return valor.trim();
}

String _limparNota(String bruto) {
  var valor = bruto.trim();
  if (valor.endsWith(']')) valor = valor.substring(0, valor.length - 1);
  return valor.trim();
}

String? _duracao(String bruto) {
  final casou = RegExp(r'\(duration: ([^)]+)\)').firstMatch(bruto);
  return casou?.group(1);
}

/// O mesmo nome que o agente vê.
///
/// Porta a regra de `gateway/run.py`: o cache guarda o arquivo como
/// `<hash>_<id>_<nome original>`, e o servidor fica com o terceiro pedaço
/// (`basename.split("_", 2)`). Divergir aqui faria a tela chamar o anexo por um
/// nome que não é o que a pessoa vê na resposta do agente.
String attachmentNameFromPath(String path) {
  final barra = path.lastIndexOf(RegExp(r'[\\/]'));
  final base = barra < 0 ? path : path.substring(barra + 1);
  final partes = base.split('_');
  final nome = partes.length >= 3 ? partes.sublist(2).join('_') : base;
  return sanitizeAttachmentName(nome);
}

/// A mesma higienização do servidor: `re.sub(r'[^\w.\- ]', '_', nome)`.
///
/// O `\w` do Python casa letra acentuada, e o do Dart não. Sem as classes
/// unicode explícitas, `Relatório.csv` viraria `Relat_rio.csv` só aqui.
String sanitizeAttachmentName(String nome) =>
    nome.replaceAll(RegExp(r'[^\p{L}\p{N}_.\- ]', unicode: true), '_');

/// Etiqueta curta do anexo: a extensão, quando existe, senão o tipo.
String attachmentTypeLabel(Attachment anexo) {
  final ponto = anexo.name.lastIndexOf('.');
  if (ponto > 0 && ponto < anexo.name.length - 1) {
    final ext = anexo.name.substring(ponto + 1);
    if (ext.length <= 5 && !ext.contains(' ')) return ext.toUpperCase();
  }
  return anexo.kind.tag;
}

/// Tamanho legível. Só é chamado quando há tamanho medido.
String attachmentSizeLabel(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${_umaCasa(kb)} KB';
  return '${_umaCasa(kb / 1024)} MB';
}

String _umaCasa(double valor) {
  final texto = valor.toStringAsFixed(1);
  // Vírgula decimal: o app fala português.
  return texto.endsWith('.0')
      ? texto.substring(0, texto.length - 2)
      : texto.replaceFirst('.', ',');
}
