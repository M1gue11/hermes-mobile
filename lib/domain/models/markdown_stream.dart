/// Divide markdown em blocos e diz **quais já estão decididos**.
///
/// Por que isto existe: durante o streaming o texto cresce a cada token, e
/// reparsar a resposta inteira a cada token custa caro. Mas nem todo pedaço do
/// texto ainda pode mudar de sentido. Um parágrafo seguido de linha em branco e
/// de um novo parágrafo está decidido: nada que chegue depois altera como ele é
/// lido. O que ainda pode mudar é só a **cauda**, o bloco que está sendo escrito
/// agora.
///
/// Esta função separa os dois. Quem desenha guarda o widget de cada bloco
/// decidido e só reconstrói a cauda.
///
/// ## As duas garantias, que não são a mesma
///
/// **Autonomia do bloco**, que é o que torna o cache correto: um bloco desenha
/// igual sozinho e dentro do documento. Quem quebra isso é a definição de
/// referência de link, que vale para o texto inteiro, inclusive para o que veio
/// antes dela; por isso a presença de uma proíbe qualquer divisão.
///
/// **Estabilidade de prefixo**, que é o que torna o cache útil: para um prefixo
/// `P` de um texto `T`, os blocos decididos de `P` são os primeiros blocos de
/// `T`. Vale para todo o corpus de teste com uma exceção conhecida: quando uma
/// definição de referência chega no fim, o documento **volta a ser um bloco
/// só**. O cache é chaveado pela fonte do bloco, então essa mudança de forma
/// redesenha em vez de mostrar o bloco velho: custa um parse, não um defeito.
///
/// Daí vêm as regras conservadoras abaixo: **na dúvida, não decida**. Um bloco
/// a mais na cauda custa um parse; um bloco decidido cedo demais desenha errado.
library;

/// Um pedaço de markdown que pode ser desenhado sozinho.
sealed class MarkdownBlock {
  const MarkdownBlock(this.source, {required this.settled});

  /// O trecho cru, como veio. É a chave de cache de quem desenha.
  final String source;

  /// Verdadeiro quando texto novo no fim do documento não muda mais este bloco.
  /// O último bloco nunca é decidido: ele é o ponto onde a escrita continua.
  final bool settled;
}

/// Prosa: parágrafo, título, lista, tabela, citação. Vai inteiro para o parser
/// de markdown.
final class MarkdownProse extends MarkdownBlock {
  const MarkdownProse(super.source, {required super.settled});
}

/// Bloco cercado por ``` na coluna zero, que o app desenha como cartão de
/// código próprio, com realce e botão de copiar.
///
/// [closed] é falso enquanto a cerca de fechamento não chegou, que é o estado
/// normal de um bloco de código enquanto o agente ainda o escreve.
final class MarkdownFence extends MarkdownBlock {
  const MarkdownFence(
    super.source, {
    required this.language,
    required this.code,
    required this.closed,
  }) : super(settled: closed);

  final String language;
  final String code;
  final bool closed;
}

/// Abertura de cerca **na coluna zero**. Cerca indentada fica de fora de
/// propósito: dentro de um item de lista ela pertence ao item, e arrancá-la
/// quebraria a lista em duas.
final _aberturaDeCerca = RegExp(r'^```([^`]*)$');
final _fechamentoDeCerca = RegExp(r'^```[ \t]*$');

/// `- item`, `* item`, `+ item`, `1. item`, `1) item`, com até 3 espaços de
/// recuo, que é o que o CommonMark aceita antes de virar código indentado.
final _itemDeLista = RegExp(r'^ {0,3}(?:[-*+]|\d{1,9}[.)])(?:[ \t]|$)');

/// Definição de referência de link (`[rotulo]: https://...`). Vale para o
/// documento inteiro, inclusive para texto **antes** dela, então a presença de
/// uma proíbe qualquer divisão.
final _definicaoDeReferencia = RegExp(r'^ {0,3}\[[^\]\n]+\]:');

/// Divide [source] em blocos, marcando os que já não podem mudar.
List<MarkdownBlock> splitMarkdownStream(String source) {
  // Uma referência definida no fim do texto muda como um link no começo é lido.
  // Dividir aqui desenharia o link como texto cru até a definição chegar, e
  // depois o consertaria: pior do que não dividir. Sai um bloco só, indeciso.
  if (_temDefinicaoDeReferencia(source)) {
    return [MarkdownProse(source, settled: false)];
  }

  final linhas = source.split('\n');
  final blocos = <MarkdownBlock>[];
  final buffer = <String>[];

  void despejarProsa({required bool settled}) {
    if (buffer.isEmpty) return;
    final texto = buffer.join('\n');
    buffer.clear();
    if (texto.trim().isEmpty) return;
    blocos.add(MarkdownProse(texto, settled: settled));
  }

  var i = 0;
  while (i < linhas.length) {
    final linha = linhas[i];

    final abertura = _aberturaDeCerca.firstMatch(linha);
    if (abertura != null) {
      // Cerca na coluna zero encerra a prosa acima em definitivo, com ou sem
      // linha em branco: nada depois dela volta a fazer parte daquele parágrafo.
      despejarProsa(settled: true);
      final corpo = <String>[];
      var j = i + 1;
      var fechada = false;
      while (j < linhas.length) {
        if (_fechamentoDeCerca.hasMatch(linhas[j])) {
          fechada = true;
          break;
        }
        corpo.add(linhas[j]);
        j++;
      }
      final fim = fechada ? j : linhas.length - 1;
      blocos.add(
        MarkdownFence(
          linhas.sublist(i, fim + 1).join('\n'),
          language: abertura.group(1)!.trim(),
          code: fechada ? '${corpo.join('\n')}\n' : corpo.join('\n'),
          closed: fechada,
        ),
      );
      i = fim + 1;
      continue;
    }

    if (linha.trim().isEmpty) {
      final proxima = _proximaLinhaComTexto(linhas, i);
      if (proxima == null) {
        // Só há branco daqui para a frente: ainda não se sabe o que vem, então
        // o bloco continua aberto. É o caso mais comum durante o streaming.
        buffer.add(linha);
        i++;
        continue;
      }
      if (_continuaDepoisDoBranco(buffer, linhas[proxima])) {
        buffer.add(linha);
        i++;
        continue;
      }
      despejarProsa(settled: true);
      i++;
      continue;
    }

    buffer.add(linha);
    i++;
  }

  // O que sobrou é a cauda: o ponto onde a escrita continua.
  if (buffer.isNotEmpty) {
    final texto = buffer.join('\n');
    if (texto.trim().isNotEmpty) {
      blocos.add(MarkdownProse(texto, settled: false));
    }
  }
  if (blocos.isEmpty) blocos.add(MarkdownProse(source, settled: false));
  return blocos;
}

bool _temDefinicaoDeReferencia(String source) {
  for (final linha in source.split('\n')) {
    if (_definicaoDeReferencia.hasMatch(linha)) return true;
  }
  return false;
}

int? _proximaLinhaComTexto(List<String> linhas, int depoisDe) {
  for (var i = depoisDe + 1; i < linhas.length; i++) {
    if (linhas[i].trim().isNotEmpty) return i;
  }
  return null;
}

/// Uma linha em branco encerra quase tudo, mas **não** encerra lista nem código
/// indentado: `- a\n\n- b` é uma lista só, frouxa, e quebrá-la em duas mudaria o
/// espaçamento de todos os itens. Mesma coisa para as duas metades de um bloco
/// indentado separadas por branco.
bool _continuaDepoisDoBranco(List<String> buffer, String proxima) {
  final ultima = _ultimaComTexto(buffer);
  if (ultima == null) return false;

  // Um callout/blockquote pode conter parágrafos, listas e outro callout
  // separados por uma linha `>`. Separar aqui faria só o primeiro parágrafo
  // conservar a caixa durante streaming.
  if (ultima.trimLeft().startsWith('>') && proxima.trimLeft().startsWith('>')) {
    return true;
  }
  if (_dentroDeContainerHtml(buffer)) return true;

  if (_dentroDeLista(buffer)) {
    return _itemDeLista.hasMatch(proxima) || _recuo(proxima) >= 2;
  }
  // Código indentado: quatro espaços de cada lado do branco.
  if (_recuo(ultima) >= 4 && _recuo(proxima) >= 4) return true;
  return false;
}

bool _dentroDeContainerHtml(List<String> buffer) {
  final source = buffer.join('\n').toLowerCase();
  for (final tag in const ['details', 'blockquote', 'dl']) {
    if (source.lastIndexOf('<$tag>') > source.lastIndexOf('</$tag>')) {
      return true;
    }
  }
  return false;
}

/// O buffer termina dentro de uma lista? Basta que exista um item de lista e
/// que a última linha com texto seja o próprio item ou uma continuação recuada
/// dele; um parágrafo colado à esquerda depois da lista já a encerrou.
bool _dentroDeLista(List<String> buffer) {
  var viuItem = false;
  String? ultima;
  for (final linha in buffer) {
    if (linha.trim().isEmpty) continue;
    if (_itemDeLista.hasMatch(linha)) {
      viuItem = true;
    } else if (viuItem && _recuo(linha) < 2) {
      viuItem = false;
    }
    ultima = linha;
  }
  if (!viuItem || ultima == null) return false;
  return _itemDeLista.hasMatch(ultima) || _recuo(ultima) >= 2;
}

String? _ultimaComTexto(List<String> buffer) {
  for (var i = buffer.length - 1; i >= 0; i--) {
    if (buffer[i].trim().isNotEmpty) return buffer[i];
  }
  return null;
}

int _recuo(String linha) {
  var conta = 0;
  for (final unidade in linha.codeUnits) {
    if (unidade == 0x20) {
      conta++;
    } else if (unidade == 0x09) {
      conta += 4;
    } else {
      break;
    }
  }
  return conta;
}
