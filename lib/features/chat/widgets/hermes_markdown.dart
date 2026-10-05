import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show OverflowBoxFit, RenderBox, RenderTable;
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_scale.dart';
import '../../../core/theme/hermes_motion.dart';
import '../../../core/theme/hermes_radius.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/code_surface.dart';
import '../../../core/widgets/unicode_spinner.dart';
import '../../../domain/models/inline_math.dart';
import '../../../domain/models/markdown_stream.dart';
import '../../settings/agent_persona.dart';

/// Markdown de leitura confortável: tipografia editorial, blocos de código
/// próprios com linguagem/cópia e elementos longos que não estouram no mobile.
///
/// Tamanho de fonte aqui vai **cru, como o design escreve**: quem converte os
/// px do mock para esta tela é o [DesignTextScaler] instalado na raiz. O
/// [designScaleOf] cobre só o que o escalonador de texto não alcança, ou seja o
/// que o CSS declara em `em`: recuo de lista, ritmo entre blocos, espaçamento
/// de letra.
///
/// ## Por que isto é um widget com estado
///
/// A resposta chega token a token, e antes o texto inteiro era reparsado a cada
/// token: um documento de tamanho médio custava ~24 ms por rebuild, numa tela
/// que tem 16,6 ms para o quadro inteiro. Agora [splitMarkdownStream] separa os
/// blocos já decididos da cauda que ainda cresce, e o widget de cada bloco
/// decidido é guardado por fonte. Devolver a **mesma instância** de widget faz
/// o `Element.updateChild` do Flutter pular a subárvore inteira, sem parse e
/// sem layout.
///
/// Com [streaming] ligado, a cauda é redesenhada a cada token e a marca braille
/// fica no ponto de escrita (A13). Como o markdown já está desenhado desde o
/// primeiro token, não existe mais a troca de árvore do fim do turno, que era o
/// refluxo do A35: ao concluir, só a marca sai.
class HermesMarkdown extends StatefulWidget {
  const HermesMarkdown(
    this.data, {
    super.key,
    this.streaming = false,
    this.spinner = 'helix',
    this.persona = const AgentPersona(),
  });

  final String data;

  /// Turno em andamento. Liga a marca no ponto de escrita e mantém a cauda
  /// fora do cache, já que ela ainda vai mudar.
  final bool streaming;

  /// Estilo da marca escolhido em Aparência.
  final String spinner;

  /// Persona usada apenas no anúncio do turno em andamento.
  final AgentPersona persona;

  @override
  State<HermesMarkdown> createState() => _HermesMarkdownState();
}

class _HermesMarkdownState extends State<HermesMarkdown> {
  /// Widget pronto de cada bloco decidido, indexado pela fonte do bloco.
  final _cache = <String, Widget>{};

  /// O cache guarda widgets já cozidos com o tema e a escala do momento da
  /// construção. Trocar de atmosfera ou de tamanho de texto invalida todos.
  Object? _tempero;

  /// O desenho inteiro da última build e a assinatura que o produziu.
  ///
  /// Uma mensagem já pronta não muda, mas a thread reconstrói: cada token de
  /// **outra** resposta faz a `ListView` reconstruir todos os itens visíveis.
  /// Sem esta memória, cada um deles remontaria a folha de estilo (dezenas de
  /// `TextStyle`, várias delas passando pelo `google_fonts`) e redividiria o
  /// texto, à toa. Era isto que pesava ao rolar a conversa durante uma resposta.
  Widget? _desenho;
  Object? _assinatura;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    final scale = designScaleOf(context);
    final tempero = Object.hash(tokens, scale);
    if (tempero != _tempero) {
      _cache.clear();
      _tempero = tempero;
    }

    final data = _prepareObsidianMarkdown(widget.data);
    final assinatura = Object.hash(
      tempero,
      data,
      widget.streaming,
      widget.spinner,
      widget.persona.displayName,
    );
    final anterior = _desenho;
    if (anterior != null && assinatura == _assinatura) return anterior;

    // Antes do primeiro token, a própria marca já identifica o turno em curso.
    // O rótulo continua disponível para tecnologia assistiva, sem acrescentar
    // texto visual ao ritmo da conversa; quando o texto chega, a mesma marca
    // segue para o fim da frase.
    if (widget.streaming && widget.data.trim().isEmpty) {
      final desenho = Semantics(
        key: const ValueKey('response-status'),
        container: true,
        liveRegion: true,
        label: widget.persona.respondingSemantics,
        child: _MarcaDeEscrita(spinner: widget.spinner, scale: scale),
      );
      _desenho = desenho;
      _assinatura = assinatura;
      return desenho;
    }

    final blocos = splitMarkdownStream(data);
    final vivas = {for (final bloco in blocos) bloco.source};
    _cache.removeWhere((chave, _) => !vivas.contains(chave));

    final folha = _styleSheet(tokens, scale);
    final filhos = <Widget>[];
    for (var i = 0; i < blocos.length; i++) {
      final bloco = blocos[i];
      // Duas prosas vizinhas são uma adjacência que não existia quando tudo ia
      // num `MarkdownBody` só, e o pacote punha `blockSpacing` entre os blocos
      // internos dele. Sem repor, o ritmo do design encolheria justamente onde
      // o texto foi dividido. Entre prosa e cartão de código nada muda: a
      // margem do cartão já era a do desenho.
      if (i > 0 && blocos[i - 1] is MarkdownProse && bloco is MarkdownProse) {
        filhos.add(SizedBox(height: folha.blockSpacing));
      }
      final ultimo = i == blocos.length - 1;
      filhos.add(
        _bloco(
          context,
          bloco,
          tokens,
          folha,
          scale,
          marca: widget.streaming && ultimo,
        ),
      );
    }

    final desenho = SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: filhos,
      ),
    );
    _desenho = desenho;
    _assinatura = assinatura;
    return desenho;
  }

  Widget _bloco(
    BuildContext context,
    MarkdownBlock bloco,
    HermesTokens tokens,
    MarkdownStyleSheet folha,
    double scale, {
    required bool marca,
  }) {
    // Turno encerrado: não há mais cauda, o documento inteiro é final. Sem esta
    // linha o último bloco de **toda** resposta já pronta seria reconstruído a
    // cada quadro da thread, que é o que pesava ao rolar a conversa.
    final cacheavel = bloco.settled || !widget.streaming;
    if (cacheavel && !marca) {
      return _cache.putIfAbsent(
        bloco.source,
        // A fronteira de repintura é metade do ganho: sem ela, crescer a cauda
        // obriga a repintar todo o texto acima dela a cada token.
        () => RepaintBoundary(
          child: _desenhar(context, bloco, tokens, folha, scale, marca: false),
        ),
      );
    }
    return _desenhar(context, bloco, tokens, folha, scale, marca: marca);
  }

  Widget _desenhar(
    BuildContext context,
    MarkdownBlock bloco,
    HermesTokens tokens,
    MarkdownStyleSheet folha,
    double scale, {
    required bool marca,
  }) {
    // Cauda de parágrafo simples: spans próprios, para a marca poder ficar
    // **dentro** da linha. Um widget inline no `MarkdownBody` não serve: o
    // pacote junta o parágrafo inteiro num `RichText` só e joga o widget
    // seguinte para a linha de baixo, que é o oposto de "no ponto de escrita".
    if (marca && bloco is MarkdownProse && _paragrafoSimples(bloco.source)) {
      return _TailParagraph(
        source: bloco.source,
        spinner: widget.spinner,
        folha: folha,
        scale: scale,
      );
    }

    final corpo = switch (bloco) {
      MarkdownFence(:final language, :final code)
          when language.toLowerCase() == 'mermaid' =>
        _MermaidDiagram(source: code, scale: scale),
      MarkdownFence(:final language, :final code) => _CodeCard(
        language: language,
        code: code,
        scale: scale,
      ),
      MarkdownProse(:final source) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final responsiveSheet = width.isFinite
              ? folha.copyWith(
                  tableColumnWidth: _FullWidthIntrinsicColumnWidth(
                    72 * scale,
                    width,
                  ),
                )
              : folha;
          return MarkdownBody(
            data: source,
            selectable: false,
            styleSheet: responsiveSheet,
            syntaxHighlighter: HermesSyntaxHighlighter(tokens),
            builders: {
              'hr': _ObsidianRule(tokens, scale),
              'mark': _HighlightBuilder(tokens),
              'display-math': _DisplayMathBuilder(tokens, scale),
              'html-blockquote': _HtmlBlockquoteBuilder(tokens, scale),
              'html-details': _HtmlDetailsBuilder(scale),
              'html-dl': _HtmlDefinitionListBuilder(tokens, scale),
              'kbd': _KeyboardKeyBuilder(tokens),
              'mermaid': _MermaidBuilder(scale),
              'obsidian-comment': _ObsidianCommentBuilder(tokens),
              'obsidian-callout': _ObsidianCalloutBuilder(scale),
              'obsidian-embed': _ObsidianEmbedBuilder(tokens, scale),
              'obsidian-tag': _ObsidianTagBuilder(tokens),
              'pre': _PreCodeBuilder(scale),
            },
            blockSyntaxes: const [
              _MermaidSyntax(),
              _ObsidianCalloutSyntax(),
              _DisplayMathSyntax(),
              _HtmlDetailsSyntax(),
              _HtmlBlockquoteSyntax(),
              _HtmlDefinitionListSyntax(),
            ],
            inlineSyntaxes: [
              _ObsidianEmbedSyntax(),
              _ObsidianWikiLinkSyntax(),
              _ObsidianTagSyntax(),
              _ObsidianCommentSyntax(),
              _KeyboardKeySyntax(),
              _HighlightSyntax(),
              _HtmlMarkSyntax(),
              _MathSyntax(),
            ],
            bulletBuilder: (parameters) =>
                _listMarker(tokens, scale, parameters),
            checkboxBuilder: (checked) =>
                _TaskBox(checked: checked, scale: scale),
            imageBuilder: (uri, title, alt) =>
                _RemoteImage(uri: uri, alt: alt ?? title),
            onTapLink: (text, href, title) => _openLink(context, tokens, href),
          );
        },
      ),
    };
    if (!marca) return corpo;

    // Cauda que não é parágrafo: lista, tabela ou código em construção. A marca
    // vai abaixo, porque não há "fim de linha" onde encaixá-la sem desmontar o
    // bloco.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        corpo,
        Padding(
          padding: EdgeInsets.only(top: 4 * scale),
          child: _MarcaDeEscrita(spinner: widget.spinner, scale: scale),
        ),
      ],
    );
  }
}

/// Remove metadados que o Obsidian apresenta fora do corpo e preserva o
/// restante da nota byte a byte. A abertura só é removida quando o delimitador
/// final já chegou, o que também mantém o streaming previsível.
String _prepareObsidianMarkdown(String source) {
  var prepared = source;
  if (prepared.startsWith('---')) {
    final frontmatter = RegExp(
      r'^---[ \t]*\r?\n[\s\S]*?\r?\n---[ \t]*(?:\r?\n|$)',
    ).firstMatch(prepared);
    if (frontmatter != null) {
      prepared = prepared.substring(frontmatter.end);
    }
  }
  return _prepareObsidianTaskStates(prepared);
}

/// O parser GFM conhece apenas `[ ]` e `[x]`. O Obsidian aceita outros
/// estados e, no tema de referência, desenha todos eles como selecionados sem
/// riscar o rótulo. Só o concluído `[x]` recebe tachado.
String _prepareObsidianTaskStates(String source) {
  final lines = source.split('\n');
  var fenced = false;
  final fence = RegExp(r'^\s*(```|~~~)');
  final completed = RegExp(r'^(\s*[-*+]\s+)\[[xX]\]\s+(.+)$');
  final extended = RegExp(r'^(\s*[-*+]\s+)\[[/\->!]\]\s+(.+)$');

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    if (fence.hasMatch(line)) {
      fenced = !fenced;
      continue;
    }
    if (fenced) continue;

    final done = completed.firstMatch(line);
    if (done != null) {
      lines[index] = '${done[1]}[x] ~~${done[2]}~~';
      continue;
    }
    final custom = extended.firstMatch(line);
    if (custom != null) {
      lines[index] = '${custom[1]}[x] ${custom[2]}';
    }
  }
  return lines.join('\n');
}

/// Linhas que abrem outro tipo de bloco, e por isso não formam um parágrafo
/// onde a marca caiba no fim da frase.
final _naoEhParagrafo = RegExp(
  r'^ {0,3}#{1,6}(?:[ \t]|$)' // título
  r'|^ {0,3}>' // citação
  r'|^ {0,3}(?:[-*+]|\d{1,9}[.)])(?:[ \t]|$)' // item de lista
  r'|^ {0,3}\|' // linha de tabela
  r'|^ {0,3}<' // html
  r'|^ {4,}' // código indentado
  r'|^ {0,3}(?:=+|-+)[ \t]*$' // sublinhado de título setext
  r'|^ {0,3}(?:([-*_])[ \t]*)\1[ \t]*\1', // regra horizontal
);

/// A cauda é um parágrafo comum, de uma ou mais linhas coladas?
///
/// Linha em branco depois de texto já significa que o parágrafo terminou e o
/// ponto de escrita passou para um bloco novo, então nem esse caso conta.
bool _paragrafoSimples(String source) {
  var viuTexto = false;
  for (final linha in source.split('\n')) {
    if (linha.trim().isEmpty) {
      if (viuTexto) return false;
      continue;
    }
    if (_naoEhParagrafo.hasMatch(linha)) return false;
    viuTexto = true;
  }
  return true;
}

MarkdownStyleSheet _styleSheet(HermesTokens t, double scale) {
  final serif = t.serif;
  final mono = t.mono;
  // `s` é para o que o escalonador de texto da raiz **não** toca: folga,
  // recuo, espaçamento de letra. Tamanho de fonte fica cru. Espessura de
  // filete também não escala, porque fio de 1px continua sendo fio de 1px.
  double s(double valor) => valor * scale;
  // Peso e itálico vêm de [HermesTokens.serifIn], nunca de um `copyWith`:
  // cada face é uma família própria no `google_fonts`.
  TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w400,
    bool italic = false,
  }) => t
      .serifIn(weight, italic: italic)
      .copyWith(fontSize: size, height: 1.7, color: color ?? t.ink);

  return MarkdownStyleSheet(
    p: body(16),
    // O CSS mede as margens de bloco em `em` do **próprio** elemento, e as
    // margens de irmãos adjacentes colapsam. Como o pacote soma
    // `blockSpacing` entre blocos, cada folga aqui é a do design menos essa
    // parcela: `p{margin-bottom:.82em}` = 13,1, logo 13,1 - 4,5.
    pPadding: EdgeInsets.only(bottom: s(8.6)),
    // `.hmd li{margin:.28em 0}` = 4,5px entre itens de lista, que é o menor
    // ritmo do design e o que aparece com mais frequência numa resposta.
    blockSpacing: s(4.5),
    // O design justifica o corpo (`.hmd p{text-align:justify;hyphens:auto}`),
    // mas a hifenização é metade da receita e o Flutter não hifeniza. Sem ela,
    // justificar numa medida de ~45 caracteres abre rios e vãos enormes: era
    // o "Link      automático:      https://..." que aparecia no aparelho.
    // Bandeira à direita é a escolha tipográfica correta sem hífen.
    textAlign: WrapAlignment.start,
    h1: t
        .serifIn(FontWeight.w600)
        .copyWith(
          fontSize: 24,
          height: 1.28,
          letterSpacing: s(-0.29),
          color: t.ink,
        ),
    // `h1{font-size:1.5em;margin:.9em 0 .45em}`: os `em` valem 24, logo 21,6
    // acima e 10,8 abaixo. Acima, a margem colapsa com os 13,1 do parágrafo
    // anterior; abaixo, sobra o `blockSpacing`.
    h1Padding: EdgeInsets.only(top: s(8.5), bottom: s(6.3)),
    h2: t
        .serifIn(FontWeight.w600)
        .copyWith(
          fontSize: 20.5,
          height: 1.28,
          letterSpacing: s(-0.25),
          color: t.ink,
        ),
    h2Padding: EdgeInsets.only(top: s(10.5), bottom: s(6.8)),
    h3: t
        .serifIn(FontWeight.w600)
        .copyWith(
          fontSize: 17.6,
          height: 1.28,
          letterSpacing: s(-0.21),
          color: t.ink,
        ),
    h3Padding: EdgeInsets.only(top: s(9), bottom: s(2.5)),
    h4: t
        .serifIn(FontWeight.w600)
        .copyWith(fontSize: 16.5, height: 1.3, color: t.ink),
    h4Padding: EdgeInsets.only(top: s(7.5), bottom: s(2)),
    h5: t
        .serifIn(FontWeight.w500)
        .copyWith(fontSize: 15.5, height: 1.35, color: t.ink),
    h5Padding: EdgeInsets.only(top: s(6), bottom: s(1.5)),
    h6: t
        .serifIn(FontWeight.w500)
        .copyWith(fontSize: 14.5, height: 1.4, color: t.dim),
    h6Padding: EdgeInsets.only(top: s(5), bottom: s(1)),
    em: body(16, italic: true),
    strong: body(16, weight: FontWeight.w600),
    a: serif.copyWith(
      fontSize: 16,
      height: 1.7,
      color: t.accent,
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: t.accent.withValues(alpha: 0.6),
      decorationThickness: 1,
    ),
    // `.hmd code{font-size:.84em}` sobre corpo de 16px.
    code: mono.copyWith(
      fontSize: 13.4,
      height: 1.62,
      color: t.ink,
      backgroundColor: Colors.transparent,
    ),
    // Como no Obsidian, a citação preserva a voz do corpo; a barra e o recuo
    // comunicam a mudança de nível sem transformar o trecho inteiro em itálico.
    blockquote: t
        .serifIn(FontWeight.w400)
        .copyWith(fontSize: 16, height: 1.65, color: t.ink),
    blockquotePadding: EdgeInsets.fromLTRB(s(14), s(2), 0, s(2)),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: t.accent.withValues(alpha: 0.65))),
    ),
    // Só vale para o marcador padrão: o nosso vem do `bulletBuilder`, que
    // pendura o marcador dentro do recuo em vez de somar largura a ele.
    listBullet: serif.copyWith(fontSize: 16, color: t.dim),
    listBulletPadding: EdgeInsets.zero,
    // `.hmd ul,.hmd ol{padding-left:1.35em}` sobre corpo de 16px.
    listIndent: s(21.6),
    // `.hmd th,.hmd td{text-align:left}`. O padrão do pacote centraliza o
    // cabeçalho, o que desalinha a primeira coluna do corpo do texto.
    tableHeadAlign: TextAlign.left,
    tableHead: t
        .monoIn(FontWeight.w500)
        .copyWith(
          fontSize: 10.5,
          color: t.dim,
          // `.hmd th{letter-spacing:.07em}` sobre os próprios 10.5px.
          letterSpacing: s(0.735),
        ),
    tableBody: serif.copyWith(fontSize: 14.4, height: 1.48, color: t.ink),
    // A tabela editorial do protótipo organiza as linhas sem fechar o conteúdo
    // numa grade. Os filetes de abertura e encerramento têm mais presença; as
    // divisórias internas ficam discretas, e não há traços verticais.
    tableBorder: TableBorder(
      top: BorderSide(color: t.ink.withValues(alpha: 0.55), width: 1.5),
      bottom: BorderSide(color: t.ink.withValues(alpha: 0.55), width: 1.5),
      horizontalInside: BorderSide(color: t.line),
    ),
    // `.hmd th,.hmd td{padding:.6em 1em .6em 0}`: o respiro vertical separa
    // cada linha dos filetes; à direita, impede colunas coladas. A ausência de
    // borda vertical deixa a primeira coluna alinhar com o corpo do texto.
    tableCellsPadding: EdgeInsets.only(
      right: s(14.4),
      top: s(8.6),
      bottom: s(8.6),
    ),
    // `.hmd table{display:block;overflow-x:auto}`. No pacote, a rolagem
    // horizontal só liga com largura fixa ou intrínseca; com a largura flex
    // padrão a tabela espreme as colunas em vez de rolar.
    // Em callouts estreitos, apenas a largura intrínseca pode encolher títulos
    // curtos até quebrá-los letra a letra. Mantemos a medida pelo conteúdo,
    // mas distribuímos qualquer largura livre entre as colunas. Tabelas curtas
    // chegam até a borda da conversa; tabelas largas preservam a medida
    // intrínseca e continuam usando a rolagem horizontal do pacote.
    tableColumnWidth: _FullWidthIntrinsicColumnWidth(s(72)),
    checkbox: mono.copyWith(color: t.accent, fontSize: 14),
  );
}

/// Continua sendo um [IntrinsicColumnWidth] para que `flutter_markdown_plus`
/// envolva tabelas largas em rolagem horizontal. O piso de cada coluna é a
/// maior medida entre a legibilidade mínima e sua fração do viewport real da
/// tabela, por isso tabelas curtas preenchem o contêiner sem espremer as longas.
class _FullWidthIntrinsicColumnWidth extends IntrinsicColumnWidth {
  const _FullWidthIntrinsicColumnWidth(
    this.minimumWidth, [
    this.availableWidth,
  ]);

  final double minimumWidth;
  final double? availableWidth;

  RenderTable? _tableOf(Iterable<RenderBox> cells) {
    final iterator = cells.iterator;
    if (!iterator.moveNext()) return null;
    final parent = iterator.current.parent;
    return parent is RenderTable ? parent : null;
  }

  @override
  double minIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    final intrinsic = super.minIntrinsicWidth(cells, containerWidth);
    return intrinsic < minimumWidth ? minimumWidth : intrinsic;
  }

  @override
  double maxIntrinsicWidth(Iterable<RenderBox> cells, double containerWidth) {
    final intrinsic = super.maxIntrinsicWidth(cells, containerWidth);
    final preferred = intrinsic < minimumWidth ? minimumWidth : intrinsic;
    final currentMinimum = minIntrinsicWidth(cells, containerWidth);
    final table = _tableOf(cells);
    final width = availableWidth;
    if (table == null || table.columns == 0 || width == null) return preferred;

    var minimumTableWidth = 0.0;
    var preferredTableWidth = 0.0;
    for (var column = 0; column < table.columns; column++) {
      final columnCells = table.column(column);
      final columnMinimum = super.minIntrinsicWidth(
        columnCells,
        double.infinity,
      );
      minimumTableWidth += columnMinimum < minimumWidth
          ? minimumWidth
          : columnMinimum;
      final columnPreferred = super.maxIntrinsicWidth(
        columnCells,
        double.infinity,
      );
      preferredTableWidth += columnPreferred < minimumWidth
          ? minimumWidth
          : columnPreferred;
    }
    if (minimumTableWidth > width) return preferred;

    if (preferredTableWidth <= width) {
      final remaining = width - preferredTableWidth;
      return preferred + remaining / table.columns;
    }

    final deficit = preferredTableWidth - width;
    final shrinkCapacity = preferredTableWidth - minimumTableWidth;
    final ownCapacity = preferred - currentMinimum;
    return preferred - deficit * ownCapacity / shrinkCapacity;
  }
}

/// A marca braille no ponto de escrita: um sinal contínuo de que o Hermes ainda
/// está escrevendo, no lugar onde o olho já está. Ver A13.
class _MarcaDeEscrita extends StatelessWidget {
  const _MarcaDeEscrita({required this.spinner, required this.scale});

  final String spinner;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return UnicodeSpinner(
      key: const ValueKey('streaming-brand'),
      name: spinner,
      size: 18 * scale,
      color: t.accentInk,
      glow: t.accent,
    );
  }
}

/// O parágrafo que está sendo escrito agora, com a marca no fim da última
/// palavra.
///
/// Por que este parágrafo não passa pelo `MarkdownBody`: o pacote funde o
/// parágrafo num `RichText` só e, se houver um widget entre os filhos inline,
/// empurra esse widget para a linha seguinte, num `Wrap`. A marca precisa ficar
/// **dentro** da linha, então aqui os spans são montados à mão a partir do
/// parse inline do mesmo parser.
///
/// Só vale enquanto o turno corre: assim que ele conclui, este parágrafo volta
/// a ser desenhado pelo `MarkdownBody` como qualquer outro. A consequência
/// assumida é que um link escrito nos últimos segundos do turno só fica
/// clicável quando o turno termina.
class _TailParagraph extends StatelessWidget {
  const _TailParagraph({
    required this.source,
    required this.spinner,
    required this.folha,
    required this.scale,
  });

  final String source;
  final String spinner;
  final MarkdownStyleSheet folha;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final base = folha.p!;
    final spans = <InlineSpan>[];

    final texto = source.trim();
    if (texto.isNotEmpty) {
      final documento = md.Document(
        extensionSet: md.ExtensionSet.gitHubFlavored,
        inlineSyntaxes: [_MathSyntax()],
      );
      _acumularSpans(documento.parseInline(texto), spans, folha, base, t);
    }

    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.only(left: 3 * scale),
          child: _MarcaDeEscrita(spinner: spinner, scale: scale),
        ),
      ),
    );

    return RichText(
      // `RichText` cru não lê o escalonador do [MediaQuery] sozinho, ao
      // contrário do `Text`. Sem isto a cauda sairia menor que o markdown já
      // decidido logo acima dela.
      textScaler: MediaQuery.textScalerOf(context),
      textAlign: TextAlign.start,
      text: TextSpan(style: base, children: spans),
    );
  }
}

/// Converte os nós inline do parser em spans, com os mesmos estilos que a folha
/// dá aos blocos já decididos: o texto não pode mudar de forma quando o turno
/// conclui e o parágrafo migra para o `MarkdownBody`.
void _acumularSpans(
  List<md.Node> nos,
  List<InlineSpan> destino,
  MarkdownStyleSheet folha,
  TextStyle atual,
  HermesTokens t, {
  bool negrito = false,
  bool italico = false,
}) {
  for (final no in nos) {
    if (no is md.Text) {
      // Mesma normalização que o pacote faz nos blocos decididos: quebra suave
      // vira espaço, senão a cauda quebraria linha onde o markdown não quebra.
      destino.add(
        TextSpan(text: no.textContent.replaceAll(RegExp(r' ?\n *'), ' ')),
      );
      continue;
    }
    if (no is! md.Element) continue;

    switch (no.tag) {
      case 'br':
        destino.add(const TextSpan(text: '\n'));
      case 'code':
        destino.add(TextSpan(text: no.textContent, style: folha.code));
      case 'em':
        _descer(no, destino, folha, atual, t, negrito: negrito, italico: true);
      case 'strong':
        _descer(no, destino, folha, atual, t, negrito: true, italico: italico);
      case 'del':
        destino.add(
          TextSpan(
            text: no.textContent,
            style: atual.copyWith(decoration: TextDecoration.lineThrough),
          ),
        );
      case 'a':
        // Sem reconhecedor de toque: o link fica clicável quando o turno
        // conclui e o parágrafo passa pelo `MarkdownBody`.
        destino.add(TextSpan(text: no.textContent, style: folha.a));
      default:
        _descer(
          no,
          destino,
          folha,
          atual,
          t,
          negrito: negrito,
          italico: italico,
        );
    }
  }
}

void _descer(
  md.Element no,
  List<InlineSpan> destino,
  MarkdownStyleSheet folha,
  TextStyle atual,
  HermesTokens t, {
  required bool negrito,
  required bool italico,
}) {
  final filhos = no.children;
  // Peso e itálico pedem a face certa: `copyWith(fontWeight:)` sobre a família
  // regular do `google_fonts` desenha um falso negrito. Ver [HermesTokens].
  final estilo = t
      .serifIn(negrito ? FontWeight.w600 : FontWeight.w400, italic: italico)
      .copyWith(
        fontSize: atual.fontSize,
        height: atual.height,
        color: atual.color,
      );
  if (filhos == null || filhos.isEmpty) {
    destino.add(TextSpan(text: no.textContent, style: estilo));
    return;
  }
  final internos = <InlineSpan>[];
  _acumularSpans(
    filhos,
    internos,
    folha,
    estilo,
    t,
    negrito: negrito,
    italico: italico,
  );
  destino.add(TextSpan(style: estilo, children: internos));
}

/// Reconhece `$...$` e `$$...$$` e emite a fórmula já convertida.
///
/// Por que sintaxe inline e não um widget: a fórmula quase sempre cai no meio
/// de uma frase (`cresce como $O(\log n)$ no número de eventos`), e um widget
/// no fluxo do parágrafo quebraria a linha ali. Emitindo nós de texto, ela
/// entra no mesmo `TextSpan` do resto e reflui com a frase.
///
/// A parte em itálico sai como `<em>`, que a folha de estilo já resolve na face
/// itálica de verdade: é assim que variável fica em itálico e nome de função em
/// texto reto, como o KaTeX faz no mock.
class _MathSyntax extends md.InlineSyntax {
  _MathSyntax() : super(r'\$\$?');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final casado = match[0]!;
    MathSpan? aqui;
    for (final span in mathSpans(parser.source)) {
      if (span.inicio == match.start) aqui = span;
    }

    if (aqui == null) {
      // Cifrão comum, de preço. Sai como texto, e **tem** de sair por aqui:
      // devolver `false` faz o `tryMatch` do pacote dar o casamento por bom
      // sem consumir nada, e o parser fica em laço no mesmo caractere.
      parser.addNode(md.Text(casado));
      return true;
    }

    for (final run in latexRuns(aqui.latex)) {
      parser.addNode(
        run.variavel
            ? md.Element('em', [md.Text(run.text)])
            : md.Text(run.text),
      );
    }
    // O `tryMatch` consome o próprio casamento (`$` ou `$$`) depois deste
    // retorno; aqui vai só o restante do trecho.
    parser.consume(aqui.fim - aqui.inicio - casado.length);
    return true;
  }
}

/// Marcador de lista.
///
/// Duas diferenças em relação ao padrão do pacote.
///
/// A primeira é a fonte: o pacote usa um único estilo para bala e número, o
/// design usa dois. `ul li::marker` herda a serifa do corpo e
/// `.hmd ol li::marker{font-family:var(--mono);font-size:.85em}`. Com um estilo
/// só, ou o número saía com serifa ou a bala saía com o desenho miúdo da mono,
/// que foi o que apareceu no aparelho.
///
/// A segunda é a posição. O pacote reserva ao marcador uma coluna de
/// `listIndent + listBulletPadding`, e o texto começa depois dela. Para o texto
/// cair nos 21,6px do design (`.hmd ul,.hmd ol{padding-left:1.35em}`), a coluna
/// tem de ser exatamente `listIndent`, com a folga por dentro. E o marcador
/// precisa poder **transbordar para a esquerda** quando não couber, como o
/// `::marker` do CSS faz: sem isso um `10.` quebra em duas linhas dentro da
/// coluna e abre um vão no meio da lista.
Widget _listMarker(
  HermesTokens t,
  double scale,
  MarkdownBulletParameters parameters,
) {
  final marcador = switch (parameters.style) {
    BulletStyle.orderedList => Text(
      '${parameters.index + 1}.',
      style: t.mono.copyWith(fontSize: 13.6, color: t.dim),
    ),
    BulletStyle.unorderedList => Text(
      '•',
      style: t.serif.copyWith(fontSize: 16, color: t.dim),
    ),
  };
  return _HangingMarker(scale: scale, child: marcador);
}

/// Encosta o marcador na direita da coluna de recuo e deixa transbordar para a
/// esquerda em vez de quebrar linha.
class _HangingMarker extends StatelessWidget {
  const _HangingMarker({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      fit: OverflowBoxFit.deferToChild,
      maxWidth: double.infinity,
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: 6 * scale),
        child: child,
      ),
    );
  }
}

/// Caixa de tarefa do design.
///
/// `.hmd input[type=checkbox]{width:1.02em;height:1.02em;border:1.5px solid
/// var(--faint);border-radius:5px}` e, marcada, fundo âmbar com o tique na cor
/// do papel. O padrão do pacote é o ícone `check_box` do Material, que traz o
/// desenho de outra família visual para dentro da resposta.
///
/// Pendura como o marcador de lista (ver [_listMarker]), para que item de bala
/// e item de tarefa comecem o texto na mesma coluna. O design faz o mesmo por
/// outro caminho: `li.task-list-item{list-style:none;margin-left:-1.15em}`.
class _TaskBox extends StatelessWidget {
  const _TaskBox({required this.checked, required this.scale});

  final bool checked;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final lado = 16.3 * scale;
    return _HangingMarker(
      scale: scale,
      child: Padding(
        padding: EdgeInsets.only(top: 4 * scale),
        child: Container(
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: checked ? t.accent : null,
            border: Border.all(color: checked ? t.accent : t.dim, width: 1.5),
            borderRadius: BorderRadius.circular(5),
          ),
          child: checked
              ? Icon(Icons.check, size: lado * 0.72, color: t.bg)
              : null,
        ),
      ),
    );
  }
}

/// Abre um link da resposta no navegador, sempre com confirmação.
///
/// O conteúdo vem do agente, não do app, então o destino é mostrado por inteiro
/// antes de sair: quem decide sair do app é a pessoa, não o modelo.
Future<void> _openLink(
  BuildContext context,
  HermesTokens t,
  String? href,
) async {
  final alvo = href?.trim();
  if (alvo == null || alvo.isEmpty) return;
  final uri = Uri.tryParse(alvo);
  if (uri == null ||
      !uri.hasScheme ||
      !const {'http', 'https', 'mailto'}.contains(uri.scheme)) {
    _avisar(context, 'Link não suportado: $alvo');
    return;
  }

  final confirmado = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: t.surface,
      title: Text(
        'Abrir fora do Hermes?',
        style: t.serif.copyWith(color: t.ink),
      ),
      content: SelectableText(
        uri.toString(),
        style: t.mono.copyWith(fontSize: 12.5, color: t.dim),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Abrir'),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return;

  final aberto = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!aberto && context.mounted) {
    _avisar(context, 'Nenhum app pôde abrir este link.');
  }
}

void _avisar(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
}

/// Imagem remota com espera e falha explícitas. Uma imagem que não carrega tem
/// de dizer isso, em vez de deixar um buraco silencioso na resposta.
class _RemoteImage extends StatelessWidget {
  const _RemoteImage({required this.uri, this.alt});

  final Uri uri;
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    // `.hmd img{max-width:100%;border-radius:11px;border:1px solid var(--line)}`
    Widget moldura(Widget child) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border.all(color: t.line),
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    Widget aviso(IconData icone, String texto) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Row(
        children: [
          Icon(icone, size: 15, color: t.dim),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: t.mono.copyWith(fontSize: 11.5, color: t.dim),
            ),
          ),
        ],
      ),
    );

    return moldura(
      Image.network(
        uri.toString(),
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : aviso(Icons.image_outlined, 'Carregando imagem…'),
        errorBuilder: (context, error, stack) => aviso(
          Icons.broken_image_outlined,
          alt?.trim().isNotEmpty == true
              ? 'Imagem indisponível: ${alt!.trim()}'
              : 'Imagem indisponível',
        ),
      ),
    );
  }
}

/// Divisor explícito da nota. Títulos não desenham regras por conta própria.
class _ObsidianRule extends MarkdownElementBuilder {
  _ObsidianRule(this.t, this.scale);
  final HermesTokens t;
  final double scale;

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      child: SizedBox(
        width: double.infinity,
        height: 1,
        child: ColoredBox(color: t.line),
      ),
    );
  }
}

class _DisplayMathSyntax extends md.BlockSyntax {
  const _DisplayMathSyntax();

  @override
  RegExp get pattern => RegExp(r'^ {0,3}\$\$[ \t]*(.*)$');

  @override
  md.Node parse(md.BlockParser parser) {
    final first = pattern.firstMatch(parser.current.content)![1]!.trim();
    parser.advance();
    final latex = <String>[];
    if (first.endsWith(r'$$') && first.length > 2) {
      latex.add(first.substring(0, first.length - 2).trimRight());
    } else {
      if (first.isNotEmpty) latex.add(first);
      while (!parser.isDone) {
        final line = parser.current.content;
        final close = RegExp(r'^(.*)\$\$[ \t]*$').firstMatch(line);
        if (close != null) {
          final before = close[1]!.trimRight();
          if (before.isNotEmpty) latex.add(before);
          parser.advance();
          break;
        }
        latex.add(line);
        parser.advance();
      }
    }
    return md.Element.empty('display-math')
      ..attributes['latex'] = latex.join('\n').trim();
  }
}

class _DisplayMathBuilder extends MarkdownElementBuilder {
  _DisplayMathBuilder(this.t, this.scale);

  final HermesTokens t;
  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final spans = <InlineSpan>[
      for (final run in latexRuns(element.attributes['latex'] ?? ''))
        TextSpan(
          text: run.text,
          style: t
              .serifIn(FontWeight.w400, italic: run.variavel)
              .copyWith(fontSize: 17, height: 1.45, color: t.ink),
        ),
    ];
    return SizedBox(
      key: const ValueKey('markdown-display-math'),
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12 * scale),
        child: Text.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _HtmlDetailsSyntax extends md.BlockSyntax {
  const _HtmlDetailsSyntax();

  @override
  RegExp get pattern =>
      RegExp(r'^ {0,3}<details>[ \t]*$', caseSensitive: false);

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();
    var summary = 'Detalhes';
    final body = <String>[];
    final summaryPattern = RegExp(
      r'^\s*<summary>(.*)</summary>\s*$',
      caseSensitive: false,
    );
    while (!parser.isDone) {
      final line = parser.current.content;
      if (RegExp(r'^\s*</details>\s*$', caseSensitive: false).hasMatch(line)) {
        parser.advance();
        break;
      }
      final heading = summaryPattern.firstMatch(line);
      if (heading != null) {
        summary = heading[1]!.trim();
      } else {
        body.add(line);
      }
      parser.advance();
    }
    return md.Element.empty('html-details')
      ..attributes['summary'] = summary
      ..attributes['body'] = body.join('\n').trim();
  }
}

class _HtmlBlockquoteSyntax extends md.BlockSyntax {
  const _HtmlBlockquoteSyntax();

  @override
  RegExp get pattern =>
      RegExp(r'^ {0,3}<blockquote>[ \t]*$', caseSensitive: false);

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();
    final body = <String>[];
    while (!parser.isDone) {
      final line = parser.current.content;
      if (RegExp(
        r'^\s*</blockquote>\s*$',
        caseSensitive: false,
      ).hasMatch(line)) {
        parser.advance();
        break;
      }
      body.add(line.trimLeft());
      parser.advance();
    }
    return md.Element.empty('html-blockquote')
      ..attributes['body'] = body.join('\n').trim();
  }
}

class _HtmlDefinitionListSyntax extends md.BlockSyntax {
  const _HtmlDefinitionListSyntax();

  @override
  RegExp get pattern => RegExp(r'^ {0,3}<dl>[ \t]*$', caseSensitive: false);

  @override
  md.Node parse(md.BlockParser parser) {
    parser.advance();
    final terms = <String>[];
    final descriptions = <String>[];
    final term = RegExp(r'^\s*<dt>(.*)</dt>\s*$', caseSensitive: false);
    final description = RegExp(r'^\s*<dd>(.*)</dd>\s*$', caseSensitive: false);
    while (!parser.isDone) {
      final line = parser.current.content;
      if (RegExp(r'^\s*</dl>\s*$', caseSensitive: false).hasMatch(line)) {
        parser.advance();
        break;
      }
      final termMatch = term.firstMatch(line);
      final descriptionMatch = description.firstMatch(line);
      if (termMatch != null) terms.add(termMatch[1]!.trim());
      if (descriptionMatch != null) {
        descriptions.add(descriptionMatch[1]!.trim());
      }
      parser.advance();
    }
    return md.Element.empty('html-dl')
      ..attributes['terms'] = terms.join('\u001f')
      ..attributes['descriptions'] = descriptions.join('\u001f');
  }
}

class _HtmlDetailsBuilder extends MarkdownElementBuilder {
  _HtmlDetailsBuilder(this.scale);

  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => _HtmlDetails(
    summary: element.attributes['summary'] ?? 'Detalhes',
    body: element.attributes['body'] ?? '',
    scale: scale,
  );
}

class _HtmlDetails extends StatefulWidget {
  const _HtmlDetails({
    required this.summary,
    required this.body,
    required this.scale,
  });

  final String summary;
  final String body;
  final double scale;

  @override
  State<_HtmlDetails> createState() => _HtmlDetailsState();
}

class _HtmlDetailsState extends State<_HtmlDetails> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final rotationMotion = motionOf(context, HermesMotion.estado);
    final revealMotion = motionOf(context, HermesMotion.revelar);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() {
                _expanded = !_expanded;
              }),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 9 * widget.scale),
                child: Row(
                  children: [
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: rotationMotion,
                      curve: HermesMotion.curvaPadrao,
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 17 * widget.scale,
                        color: t.dim,
                      ),
                    ),
                    SizedBox(width: 5 * widget.scale),
                    Text(
                      widget.summary,
                      style: t.serif.copyWith(fontSize: 15, color: t.ink),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: revealMotion,
            curve: HermesMotion.curvaPadrao,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.only(
                      left: 22 * widget.scale,
                      bottom: 8 * widget.scale,
                    ),
                    child: HermesMarkdown(widget.body),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _HtmlBlockquoteBuilder extends MarkdownElementBuilder {
  _HtmlBlockquoteBuilder(this.t, this.scale);

  final HermesTokens t;
  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 14 * scale),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: t.accent.withValues(alpha: 0.65)),
        ),
      ),
      child: HermesMarkdown(element.attributes['body'] ?? ''),
    );
  }
}

class _HtmlDefinitionListBuilder extends MarkdownElementBuilder {
  _HtmlDefinitionListBuilder(this.t, this.scale);

  final HermesTokens t;
  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final terms = (element.attributes['terms'] ?? '').split('\u001f');
    final descriptions = (element.attributes['descriptions'] ?? '').split(
      '\u001f',
    );
    return Column(
      key: const ValueKey('markdown-definition-list'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < terms.length; index++) ...[
          Text(
            terms[index],
            style: t
                .serifIn(FontWeight.w600)
                .copyWith(fontSize: 15, color: t.ink),
          ),
          if (index < descriptions.length)
            Padding(
              padding: EdgeInsets.only(left: 22 * scale, top: 3 * scale),
              child: Text(
                descriptions[index],
                style: t.serif.copyWith(fontSize: 15, color: t.dim),
              ),
            ),
          if (index < terms.length - 1) SizedBox(height: 10 * scale),
        ],
      ],
    );
  }
}

class _ObsidianCalloutSyntax extends md.BlockSyntax {
  const _ObsidianCalloutSyntax();

  @override
  RegExp get pattern => RegExp(
    r'^ {0,3}>[ \t]*\[!([A-Za-z0-9_-]+)\]([+-])?(?:[ \t]+(.*))?[ \t]*$',
    caseSensitive: false,
  );

  @override
  md.Node parse(md.BlockParser parser) {
    final match = pattern.firstMatch(parser.current.content)!;
    final type = match[1]!.toLowerCase();
    final behavior = match[2] ?? '';
    final suppliedTitle = match[3]?.trim();
    parser.advance();

    final body = <String>[];
    final quoted = RegExp(r'^ {0,3}>[ \t]?(.*)$');
    while (!parser.isDone) {
      final line = quoted.firstMatch(parser.current.content);
      if (line == null) break;
      body.add(line[1] ?? '');
      parser.advance();
    }

    return md.Element.empty('obsidian-callout')
      ..attributes['type'] = type
      ..attributes['title'] = suppliedTitle?.isNotEmpty == true
          ? suppliedTitle!
          : type
      ..attributes['behavior'] = behavior
      ..attributes['body'] = body.join('\n');
  }
}

class _ObsidianCalloutBuilder extends MarkdownElementBuilder {
  _ObsidianCalloutBuilder(this.scale);

  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return _ObsidianCallout(
      type: element.attributes['type'] ?? 'note',
      title: element.attributes['title'] ?? 'note',
      behavior: element.attributes['behavior'] ?? '',
      body: element.attributes['body'] ?? '',
      scale: scale,
    );
  }
}

class _ObsidianCallout extends StatefulWidget {
  const _ObsidianCallout({
    required this.type,
    required this.title,
    required this.behavior,
    required this.body,
    required this.scale,
  });

  final String type;
  final String title;
  final String behavior;
  final String body;
  final double scale;

  @override
  State<_ObsidianCallout> createState() => _ObsidianCalloutState();
}

class _ObsidianCalloutState extends State<_ObsidianCallout> {
  late bool _expanded;

  bool get _collapsible => widget.behavior.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _expanded = widget.behavior != '-';
  }

  @override
  void didUpdateWidget(covariant _ObsidianCallout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.behavior != widget.behavior) {
      _expanded = widget.behavior != '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final rotationMotion = motionOf(context, HermesMotion.estado);
    final revealMotion = motionOf(context, HermesMotion.revelar);
    final visual = _calloutVisual(widget.type, t);
    final radius = HermesRadius.todos(HermesRadius.bloco);
    final header = Row(
      children: [
        Icon(visual.icon, size: 16 * widget.scale, color: visual.color),
        SizedBox(width: 7 * widget.scale),
        Expanded(
          child: Text(
            widget.title,
            style: t
                .serifIn(FontWeight.w600)
                .copyWith(fontSize: 15, height: 1.3, color: visual.color),
          ),
        ),
        if (_collapsible)
          AnimatedRotation(
            turns: _expanded ? 0.25 : 0,
            duration: rotationMotion,
            curve: HermesMotion.curvaPadrao,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18 * widget.scale,
              color: visual.color,
            ),
          ),
      ],
    );

    return Container(
      key: ValueKey('obsidian-callout-${widget.type}-${widget.title}'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.1),
        border: Border.all(color: visual.color.withValues(alpha: 0.22)),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(12 * widget.scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_collapsible)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: radius,
                  onTap: () => setState(() {
                    _expanded = !_expanded;
                  }),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2 * widget.scale),
                    child: header,
                  ),
                ),
              )
            else
              header,
            AnimatedSize(
              duration: revealMotion,
              curve: HermesMotion.curvaPadrao,
              alignment: Alignment.topCenter,
              child: _expanded && widget.body.trim().isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.only(top: 8 * widget.scale),
                      child: HermesMarkdown(widget.body),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}

({Color color, IconData icon}) _calloutVisual(String rawType, HermesTokens t) {
  final type = rawType.toLowerCase();
  if (const {'abstract', 'summary', 'tldr'}.contains(type)) {
    return (color: t.cType, icon: Icons.content_paste_outlined);
  }
  if (const {'tip', 'hint', 'important'}.contains(type)) {
    return (color: t.cStr, icon: Icons.local_fire_department_outlined);
  }
  if (const {'success', 'check', 'done'}.contains(type)) {
    return (color: t.positive, icon: Icons.check_rounded);
  }
  if (const {'question', 'help', 'faq'}.contains(type)) {
    return (color: t.accent, icon: Icons.help_outline_rounded);
  }
  if (const {'warning', 'caution', 'attention'}.contains(type)) {
    return (color: t.accent, icon: Icons.warning_amber_rounded);
  }
  if (const {'failure', 'fail', 'missing'}.contains(type)) {
    return (color: t.accentInk, icon: Icons.close_rounded);
  }
  if (const {'danger', 'error'}.contains(type)) {
    return (color: t.accentInk, icon: Icons.bolt_rounded);
  }
  if (type == 'bug') {
    return (color: t.accentInk, icon: Icons.bug_report_outlined);
  }
  if (type == 'example') {
    return (color: t.cFn, icon: Icons.format_list_bulleted_rounded);
  }
  if (const {'quote', 'cite'}.contains(type)) {
    return (color: t.dim, icon: Icons.format_quote_rounded);
  }
  if (type == 'idea') {
    return (color: t.cNum, icon: Icons.lightbulb_outline_rounded);
  }
  if (type == 'todo') {
    return (color: t.accent, icon: Icons.check_circle_outline_rounded);
  }
  if (type == 'info') {
    return (color: t.accent, icon: Icons.info_outline_rounded);
  }
  return (color: t.accent, icon: Icons.edit_outlined);
}

class _ObsidianWikiLinkSyntax extends md.InlineSyntax {
  _ObsidianWikiLinkSyntax() : super(r'\[\[([^\]\n]+)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final raw = match[1]!;
    final separator = raw.indexOf('|');
    final target = separator < 0 ? raw : raw.substring(0, separator);
    var label = separator < 0 ? raw : raw.substring(separator + 1);
    if (label.startsWith('#')) label = label.substring(1);
    final link = md.Element.text('a', label)
      ..attributes['href'] = Uri(scheme: 'obsidian', path: target).toString();
    parser.addNode(link);
    return true;
  }
}

class _ObsidianEmbedSyntax extends md.InlineSyntax {
  _ObsidianEmbedSyntax() : super(r'!\[\[([^\]\n]+)\]\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.empty('obsidian-embed')
      ..attributes['target'] = match[1]!;
    parser.addNode(element);
    return true;
  }
}

class _ObsidianTagSyntax extends md.InlineSyntax {
  _ObsidianTagSyntax()
    : super(
        r'(?<![\w/])#([A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*)',
        startCharacter: 35,
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('obsidian-tag', '#${match[1]}'));
    return true;
  }
}

class _ObsidianCommentSyntax extends md.InlineSyntax {
  _ObsidianCommentSyntax() : super(r'%%([\s\S]*?)%%');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('obsidian-comment', match[1]!));
    return true;
  }
}

class _KeyboardKeySyntax extends md.InlineSyntax {
  _KeyboardKeySyntax() : super(r'<kbd>([^<\n]+)</kbd>', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('kbd', match[1]!));
    return true;
  }
}

class _HighlightSyntax extends md.InlineSyntax {
  _HighlightSyntax() : super(r'==([^=\n]+)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[1]!));
    return true;
  }
}

class _HtmlMarkSyntax extends md.InlineSyntax {
  _HtmlMarkSyntax() : super(r'<mark>([^<\n]+)</mark>', caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('mark', match[1]!));
    return true;
  }
}

class _HighlightBuilder extends MarkdownElementBuilder {
  _HighlightBuilder(this.t);

  final HermesTokens t;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          element.textContent,
          style: (parentStyle ?? t.serif).copyWith(color: t.ink),
        ),
      ),
    );
  }
}

class _ObsidianTagBuilder extends MarkdownElementBuilder {
  _ObsidianTagBuilder(this.t);

  final HermesTokens t;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          element.textContent,
          style: t.mono.copyWith(fontSize: 11.5, color: t.accent),
        ),
      ),
    );
  }
}

class _ObsidianCommentBuilder extends MarkdownElementBuilder {
  _ObsidianCommentBuilder(this.t);

  final HermesTokens t;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Text(
      '%%${element.textContent}%%',
      style: (parentStyle ?? t.serif).copyWith(color: t.dim),
    );
  }
}

class _KeyboardKeyBuilder extends MarkdownElementBuilder {
  _KeyboardKeyBuilder(this.t);

  final HermesTokens t;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: t.codeInline,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.textContent,
        style: t.mono.copyWith(fontSize: 11.5, color: t.ink),
      ),
    );
  }
}

class _ObsidianEmbedBuilder extends MarkdownElementBuilder {
  _ObsidianEmbedBuilder(this.t, this.scale);

  final HermesTokens t;
  final double scale;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final target = element.attributes['target'] ?? 'conteúdo local';
    final lower = target.toLowerCase();
    final isImage = RegExp(
      r'\.(?:png|jpe?g|gif|webp|svg)(?:\||$)',
    ).hasMatch(lower);
    final isPdf = lower.contains('.pdf');
    final icon = isImage
        ? Icons.image_outlined
        : isPdf
        ? Icons.picture_as_pdf_outlined
        : Icons.note_outlined;
    final message = isImage
        ? 'Imagem local não encontrada: $target'
        : isPdf
        ? 'PDF local não encontrado: $target'
        : 'Nota local não encontrada: $target';

    return Container(
      constraints: BoxConstraints(maxWidth: 280 * scale),
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.line),
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15 * scale, color: t.faint),
          SizedBox(width: 7 * scale),
          Flexible(
            child: Text(
              message,
              style: t.mono.copyWith(
                fontSize: 10.5,
                height: 1.35,
                color: t.dim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bloco de código.
///
/// O corpo continua sem faixa de cabeçalho, mas blocos identificados exibem a
/// linguagem em tinta discreta, como a referência do Obsidian. O botão de
/// cópia permanece acessível no touch.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.language, required this.code, this.scale = 1});

  final String language;

  String get languageLabel => switch (language.toLowerCase()) {
    'py' || 'python' => 'PYTHON',
    'sh' || 'shell' || 'bash' => 'SHELL',
    'js' || 'javascript' => 'JAVASCRIPT',
    'ts' || 'typescript' => 'TYPESCRIPT',
    final value => value.toUpperCase(),
  };

  final String code;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    double s(double valor) => valor * scale;
    return Container(
      key: const ValueKey('markdown-code-card'),
      margin: EdgeInsets.only(top: s(3), bottom: s(18)),
      child: CodeSurface(
        scale: scale,
        shadowKey: const ValueKey('markdown-code-inset-shadow'),
        child: Stack(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // `padding:15px 16px 13px`, exatamente como o design, já que não
              // há faixa comendo o topo. A folga extra à direita é o espaço do
              // botão, para ele não cair sobre a primeira linha.
              padding: EdgeInsets.fromLTRB(s(16), s(15), s(48), s(13)),
              // `Text.rich`, e não `SelectableText.rich`: o cartão já vive
              // dentro do `SelectionArea` do [HermesMarkdown], que torna
              // qualquer texto descendente selecionável. O `SelectableText`
              // monta um `EditableText` inteiro por bloco e ainda se recusa a
              // participar da seleção da área, quebrando o arrasto que atravessa
              // texto e código. Medido: a primeira construção de um cartão de
              // código custava 84 ms no quadro em que a cerca abre.
              child: Text.rich(HermesSyntaxHighlighter(t).format(code)),
            ),
            // Fora do `SingleChildScrollView` de propósito: o botão fica parado
            // enquanto o código rola na horizontal.
            // Encostado no canto para invadir o mínimo possível da primeira
            // linha: um botão sobreposto num bloco que rola na horizontal
            // sempre cobre algum código, e a alternativa seria empurrar o
            // código para baixo, afastando do `padding:15px 16px 13px`.
            Positioned(
              top: s(4),
              right: s(4),
              child: _CopyCodeButton(code: code, scale: scale),
            ),
            if (languageLabel.isNotEmpty)
              Positioned(
                top: s(10),
                right: s(39),
                child: Text(
                  languageLabel,
                  key: const ValueKey('markdown-code-language'),
                  style: t.mono.copyWith(
                    fontSize: 8.5,
                    letterSpacing: s(0.6),
                    color: t.dim,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fences que permanecem dentro de um [MarkdownBody] também usam o cartão
/// canônico. Isso acontece quando uma definição de referência exige que o
/// documento inteiro seja parseado junto; sem este builder, o `<pre>` interno
/// do pacote perdia o fundo rebaixado, a sombra e a ação de copiar.
class _PreCodeBuilder extends MarkdownElementBuilder {
  _PreCodeBuilder(this.scale);

  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    var language = '';
    for (final child in element.children ?? const <md.Node>[]) {
      if (child is! md.Element || child.tag != 'code') continue;
      final classes = child.attributes['class'] ?? '';
      final match = RegExp(r'(?:^|\s)language-([^\s]+)').firstMatch(classes);
      language = match?[1] ?? '';
      break;
    }
    return _CodeCard(
      language: language,
      code: element.textContent,
      scale: scale,
    );
  }
}

class _MermaidDiagram extends StatelessWidget {
  const _MermaidDiagram({required this.source, required this.scale});

  final String source;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final trimmed = source.trimLeft();
    if (trimmed.startsWith('flowchart ') || trimmed.startsWith('graph ')) {
      final graph = _parseMermaidFlowchart(source);
      if (graph != null) {
        return _MermaidFlowchart(graph: graph, source: source, scale: scale);
      }
    }
    if (trimmed.startsWith('sequenceDiagram')) {
      final sequence = _parseMermaidSequence(source);
      if (sequence != null) {
        return _MermaidSequence(
          sequence: sequence,
          source: source,
          scale: scale,
        );
      }
    }
    return _CodeCard(language: 'mermaid', code: source, scale: scale);
  }
}

/// Intercepta cercas Mermaid também quando o documento precisa permanecer em
/// um único [MarkdownBody] (por exemplo, por conter referências de link).
/// Cercas separadas pelo streaming continuam usando [MarkdownFence].
class _MermaidSyntax extends md.BlockSyntax {
  const _MermaidSyntax();

  @override
  RegExp get pattern =>
      RegExp(r'^ {0,3}`{3,}[ \t]*mermaid[ \t]*$', caseSensitive: false);

  @override
  md.Node parse(md.BlockParser parser) {
    final opening = parser.current.content;
    final marker = RegExp(r'^ {0,3}(`{3,})').firstMatch(opening)![1]!;
    parser.advance();
    final body = <String>[];
    final closing = RegExp('^ {0,3}${RegExp.escape(marker)}[ `\\t]*\$');
    while (!parser.isDone) {
      final line = parser.current.content;
      if (closing.hasMatch(line)) {
        parser.advance();
        break;
      }
      body.add(line);
      parser.advance();
    }
    return md.Element.empty('mermaid')..attributes['source'] = body.join('\n');
  }
}

class _MermaidBuilder extends MarkdownElementBuilder {
  _MermaidBuilder(this.scale);

  final double scale;

  @override
  bool isBlockElement() => true;

  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) =>
      _MermaidDiagram(source: element.attributes['source'] ?? '', scale: scale);
}

typedef _MermaidNode = ({String id, String label, bool decision});
typedef _MermaidEdge = ({String from, String to, String label});
typedef _MermaidFlowGraph = ({
  _MermaidNode root,
  _MermaidNode decision,
  List<({_MermaidNode node, String label})> branches,
});

_MermaidFlowGraph? _parseMermaidFlowchart(String source) {
  final nodes = <String, _MermaidNode>{};
  final edges = <_MermaidEdge>[];
  final edge = RegExp(
    r'^\s*([A-Za-z0-9_]+)(?:\[([^\]]+)\]|\{([^}]+)\})?\s*-->'
    r'\s*(?:\|([^|]+)\|\s*)?([A-Za-z0-9_]+)'
    r'(?:\[([^\]]+)\]|\{([^}]+)\})?\s*$',
  );
  for (final line in source.split('\n')) {
    final match = edge.firstMatch(line);
    if (match == null) continue;
    _MermaidNode node(int id, int box, int diamond) {
      final identifier = match[id]!;
      final decision = match[diamond] != null;
      final label = match[box] ?? match[diamond] ?? identifier;
      return (id: identifier, label: label, decision: decision);
    }

    final from = node(1, 2, 3);
    final to = node(5, 6, 7);
    void remember(_MermaidNode value) {
      final current = nodes[value.id];
      if (current == null || value.label != value.id || value.decision) {
        nodes[value.id] = value;
      }
    }

    remember(from);
    remember(to);
    edges.add((from: from.id, to: to.id, label: match[4]?.trim() ?? ''));
  }
  if (edges.isEmpty) return null;
  final incoming = {for (final item in edges) item.to};
  final rootId = nodes.keys.firstWhere(
    (id) => !incoming.contains(id),
    orElse: () => edges.first.from,
  );
  final first = edges.where((item) => item.from == rootId).firstOrNull;
  if (first == null) return null;
  final decision = nodes[first.to]!;
  final branches = [
    for (final item in edges.where((edge) => edge.from == decision.id))
      (node: nodes[item.to]!, label: item.label),
  ];
  if (branches.isEmpty) return null;
  return (root: nodes[rootId]!, decision: decision, branches: branches);
}

class _MermaidFlowchart extends StatelessWidget {
  const _MermaidFlowchart({
    required this.graph,
    required this.source,
    required this.scale,
  });

  final _MermaidFlowGraph graph;
  final String source;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return _DiagramSurface(
      key: const ValueKey('mermaid-flowchart'),
      label: 'FLUXO',
      source: source,
      scale: scale,
      child: Column(
        children: [
          _DiagramNode(label: graph.root.label, scale: scale),
          _DownConnector(scale: scale),
          CustomPaint(
            painter: _DiamondPainter(
              fill: t.accent.withValues(alpha: 0.09),
              stroke: t.accent.withValues(alpha: 0.55),
            ),
            child: SizedBox(
              width: 152 * scale,
              height: 88 * scale,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30 * scale),
                  child: Text(
                    graph.decision.label,
                    textAlign: TextAlign.center,
                    style: t.serif.copyWith(
                      fontSize: 13,
                      height: 1.25,
                      color: t.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 14 * scale),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8 * scale,
            runSpacing: 10 * scale,
            children: [
              for (final branch in graph.branches)
                SizedBox(
                  width: 92 * scale,
                  child: Column(
                    children: [
                      Text(
                        branch.label,
                        style: t.mono.copyWith(fontSize: 9, color: t.dim),
                      ),
                      SizedBox(height: 4 * scale),
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 13 * scale,
                        color: t.dim,
                      ),
                      SizedBox(height: 4 * scale),
                      _DiagramNode(label: branch.node.label, scale: scale),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  const _DiamondPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) =>
      fill != oldDelegate.fill || stroke != oldDelegate.stroke;
}

typedef _SequenceEvent = ({
  String from,
  String to,
  String message,
  bool dashed,
});
typedef _MermaidSequenceData = ({
  Map<String, String> participants,
  List<_SequenceEvent> events,
});

_MermaidSequenceData? _parseMermaidSequence(String source) {
  final participants = <String, String>{};
  final events = <_SequenceEvent>[];
  final participant = RegExp(
    r'^\s*participant\s+([A-Za-z0-9_]+)(?:\s+as\s+(.+))?$',
    caseSensitive: false,
  );
  final message = RegExp(
    r'^\s*([A-Za-z0-9_]+)\s*(-->>|->>|-->|->)\s*([A-Za-z0-9_]+)\s*:\s*(.+)$',
  );
  for (final line in source.split('\n')) {
    final person = participant.firstMatch(line);
    if (person != null) {
      participants[person[1]!] = person[2]?.trim() ?? person[1]!;
      continue;
    }
    final event = message.firstMatch(line);
    if (event != null) {
      participants.putIfAbsent(event[1]!, () => event[1]!);
      participants.putIfAbsent(event[3]!, () => event[3]!);
      events.add((
        from: event[1]!,
        to: event[3]!,
        message: event[4]!.trim(),
        dashed: event[2]!.startsWith('--'),
      ));
    }
  }
  if (participants.isEmpty || events.isEmpty) return null;
  return (participants: participants, events: events);
}

class _MermaidSequence extends StatelessWidget {
  const _MermaidSequence({
    required this.sequence,
    required this.source,
    required this.scale,
  });

  final _MermaidSequenceData sequence;
  final String source;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return _DiagramSurface(
      key: const ValueKey('mermaid-sequence'),
      label: 'SEQUÊNCIA',
      source: source,
      scale: scale,
      child: Column(
        children: [
          Row(
            children: [
              for (final label in sequence.participants.values)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2 * scale),
                    child: _DiagramNode(label: label, scale: scale),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14 * scale),
          for (final event in sequence.events)
            Padding(
              padding: EdgeInsets.only(bottom: 12 * scale),
              child: Column(
                children: [
                  Text(
                    event.message,
                    textAlign: TextAlign.center,
                    style: t.serif.copyWith(fontSize: 12.5, color: t.ink),
                  ),
                  SizedBox(height: 5 * scale),
                  Row(
                    children: [
                      SizedBox(
                        width: 58 * scale,
                        child: Text(
                          sequence.participants[event.from]!,
                          overflow: TextOverflow.ellipsis,
                          style: t.mono.copyWith(fontSize: 8.5, color: t.dim),
                        ),
                      ),
                      Expanded(
                        child: CustomPaint(
                          painter: _SequenceLinePainter(
                            color: t.dim,
                            dashed: event.dashed,
                          ),
                          child: SizedBox(height: 10 * scale),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 12 * scale,
                        color: t.dim,
                      ),
                      SizedBox(
                        width: 58 * scale,
                        child: Text(
                          sequence.participants[event.to]!,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: t.mono.copyWith(fontSize: 8.5, color: t.dim),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SequenceLinePainter extends CustomPainter {
  const _SequenceLinePainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 4).clamp(0, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SequenceLinePainter oldDelegate) =>
      color != oldDelegate.color || dashed != oldDelegate.dashed;
}

class _DiagramSurface extends StatelessWidget {
  const _DiagramSurface({
    super.key,
    required this.label,
    required this.source,
    required this.scale,
    required this.child,
  });

  final String label;
  final String source;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    // O cabeçalho é legenda, não conteúdo: ele encosta na borda de cima em vez
    // de respeitar o respiro do bloco. O que sai do padding volta antes do
    // diagrama, então a linha inteira — ícone, rótulo e botão — sobe sem mexer
    // na altura do bloco nem na posição do desenho. Não escala porque compensa
    // a caixa do texto, que também tem corpo fixo.
    const subidaDoCabecalho = 8.5;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 3 * scale, bottom: 18 * scale),
      padding: EdgeInsets.fromLTRB(
        14 * scale,
        14 * scale - subidaDoCabecalho,
        14 * scale,
        14 * scale,
      ),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.line),
        borderRadius: HermesRadius.todos(HermesRadius.bloco),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 14 * scale,
                color: t.accent,
              ),
              SizedBox(width: 6 * scale),
              Expanded(
                // Sobra da subida da linha: a caixa da mono deixa a tinta
                // abaixo do centro óptico do ícone.
                child: Transform.translate(
                  offset: const Offset(0, -1.5),
                  child: Text(
                    'MERMAID · $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.mono.copyWith(
                      fontSize: 8.5,
                      letterSpacing: 0.8 * scale,
                      color: t.dim,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              _CopyCodeButton(
                key: const ValueKey('mermaid-copy-code'),
                // O parser preserva a quebra estrutural imediatamente antes
                // da cerca de fechamento. Ela não pertence ao código copiado.
                code: source.replaceFirst(RegExp(r'\r?\n$'), ''),
                scale: scale,
              ),
            ],
          ),
          SizedBox(height: 14 * scale + subidaDoCabecalho),
          Center(child: child),
        ],
      ),
    );
  }
}

class _DiagramNode extends StatelessWidget {
  const _DiagramNode({required this.label, required this.scale});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final style = t.serif.copyWith(fontSize: 11.5, height: 1.2, color: t.ink);
    final singleWord = !label.trim().contains(RegExp(r'\s'));
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9 * scale, vertical: 7 * scale),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.08),
        border: Border.all(color: t.accent.withValues(alpha: 0.42)),
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: singleWord
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: style,
              ),
            )
          : Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: style,
            ),
    );
  }
}

class _DownConnector extends StatelessWidget {
  const _DownConnector({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Icon(Icons.arrow_downward_rounded, size: 16 * scale, color: t.dim),
    );
  }
}

/// Botão de copiar sobreposto ao bloco. Fica sobre o próprio fundo do código,
/// então ganha uma pastilha opaca para não brigar com o texto embaixo.
class _CopyCodeButton extends StatelessWidget {
  const _CopyCodeButton({super.key, required this.code, required this.scale});

  final String code;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final lado = 28 * scale;
    return Tooltip(
      message: 'Copiar código',
      child: Material(
        color: t.bg2,
        shape: CircleBorder(side: BorderSide(color: t.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Código copiado')));
            }
          },
          child: SizedBox(
            width: lado,
            height: lado,
            child: Icon(
              Icons.content_copy_outlined,
              size: 15 * scale,
              color: t.dim,
            ),
          ),
        ),
      ),
    );
  }
}

/// Realce de sintaxe leve e agnóstico de linguagem (dart/ts/json/py), usando as
/// cores de token do tema. Faz um único passo linear sobre o código.
///
/// A atribuição segue a tabela hljs do design (`design/Hermes.dc.html`, seção
/// `/* hljs */`), que é o que faz as duas telas parecerem a mesma:
///
/// | Classe do design | Cor | Aqui |
/// | --- | --- | --- |
/// | `.hljs-comment`, `.hljs-quote` | `--faint`, itálico | grupo `comment` |
/// | `.hljs-keyword`, `.hljs-literal` | `--cKey` | palavra em `_keywords` |
/// | `.hljs-string`, `.hljs-regexp` | `--cStr` | grupo `string` |
/// | `.hljs-number`, `.hljs-symbol` | `--cNum` | grupo `number` |
/// | `.hljs-title.function_` | `--cFn` | identificador seguido de `(` |
/// | `.hljs-type`, `.hljs-title.class_` | `--cType` | identificador capitalizado |
/// | `.hljs-property`, `.hljs-variable` | `--ink` | os demais |
class HermesSyntaxHighlighter extends SyntaxHighlighter {
  HermesSyntaxHighlighter(
    this.t, {
    this.fontSize = 12.5,
    this.lineHeight = 1.62,
    this.plainColor,
  });

  final HermesTokens t;
  final double fontSize;
  final double lineHeight;
  final Color? plainColor;

  static final RegExp _scanner = RegExp(
    r'(?<comment>//[^\n]*|#[^\n]*|/\*[\s\S]*?\*/)'
    r'|(?<string>"(?:\\.|[^"\\])*"|'
    "'(?:\\\\.|[^'\\\\])*'"
    r'|`(?:\\.|[^`\\])*`)'
    r'|(?<number>\b\d[\d_]*(?:\.\d+)?\b)'
    r'|(?<ident>[A-Za-z_]\w*)',
    multiLine: true,
  );

  static const Set<String> _keywords = {
    'abstract',
    'as',
    'async',
    'await',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'def',
    'default',
    'else',
    'enum',
    'export',
    'extends',
    'factory',
    'final',
    'finally',
    'for',
    'from',
    'function',
    'get',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'let',
    'new',
    'null',
    'of',
    'required',
    'return',
    'set',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'false',
    'try',
    'type',
    'typedef',
    'var',
    'void',
    'while',
    'with',
    'yield',
  };

  @override
  TextSpan format(String source) {
    final spans = <TextSpan>[];
    // `.hmd pre{font-size:12.5px;line-height:1.62}`.
    final base = t.mono.copyWith(
      fontSize: fontSize,
      height: lineHeight,
      color: plainColor ?? t.ink,
    );
    // `.hljs-comment{font-style:italic}`. Precisa da face itálica de verdade,
    // não de um `fontStyle` sobre a família da regular. Ver [HermesTokens.monoIn].
    final comentario = t
        .monoIn(FontWeight.w400, italic: true)
        .copyWith(fontSize: fontSize, height: lineHeight, color: t.dim);
    var last = 0;

    void plain(int end) {
      if (end > last) {
        spans.add(TextSpan(text: source.substring(last, end), style: base));
      }
    }

    for (final m in _scanner.allMatches(source)) {
      plain(m.start);
      final text = m.group(0)!;
      Color color;
      var italic = false;
      if (m.namedGroup('comment') != null) {
        color = t.dim;
        italic = true;
      } else if (m.namedGroup('string') != null) {
        color = t.cStr;
      } else if (m.namedGroup('number') != null) {
        color = t.cNum;
      } else if (_keywords.contains(text)) {
        color = t.cKey;
      } else {
        final next = m.end < source.length ? source[m.end] : '';
        color = next == '('
            ? t.cFn
            : (text[0].toUpperCase() == text[0] &&
                  text[0] != text[0].toLowerCase())
            ? t.cType
            : t.ink;
      }
      spans.add(
        TextSpan(
          text: text,
          style: italic ? comentario : base.copyWith(color: color),
        ),
      );
      last = m.end;
    }
    plain(source.length);
    return TextSpan(style: base, children: spans);
  }
}
