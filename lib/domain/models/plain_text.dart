import 'inline_math.dart';

/// Converte a resposta em markdown para o texto que está **na tela**.
///
/// Não é remover marcação por remover: é reproduzir a leitura. Por isso o bloco
/// de código perde a cerca mas mantém o código inteiro, a tarefa vira `☑`/`☐`
/// como o quadradinho desenhado, o `hr` vira o fleurão que o design pinta, e a
/// fórmula passa pelo mesmo conversor da tela, para colar `O(log n)` e não
/// `$O(\log n)$`.
///
/// A única coisa que ganha texto em vez de perder é o link: na tela o endereço
/// mora no toque, e num texto colado ele não se recupera de lugar nenhum, então
/// sai como `rótulo (url)`.
String markdownToPlainText(String source) {
  final saida = <String>[];
  var emCodigo = false;

  for (final linha in source.split('\n')) {
    if (_cerca.hasMatch(linha)) {
      emCodigo = !emCodigo;
      continue;
    }
    if (emCodigo) {
      saida.add(linha);
      continue;
    }
    if (_regraHorizontal.hasMatch(linha)) {
      saida.add('❦');
      continue;
    }
    // A linha de trações da tabela desenha o filete; no texto ela é ruído.
    if (_separadorDeTabela.hasMatch(linha)) continue;

    var texto = linha;
    texto = texto.replaceFirst(_titulo, '');
    texto = texto.replaceFirst(_citacao, '');
    texto = texto.replaceFirstMapped(
      _tarefa,
      (m) => '${m[1]}${m[2]!.trim().isEmpty ? '☐' : '☑'} ',
    );
    texto = texto.replaceFirstMapped(_bala, (m) => '${m[1]}• ');
    if (_linhaDeTabela.hasMatch(texto)) {
      texto = texto
          .trim()
          .replaceAll(RegExp(r'^\||\|$'), '')
          .split('|')
          .map((celula) => celula.trim())
          .join('\t');
    }
    saida.add(_inline(texto));
  }

  // Sobra de conversão: no máximo uma linha em branco entre blocos.
  return saida
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Marcação de dentro da linha.
///
/// Trecho de código e fórmula saem de cena primeiro, guardados atrás de um
/// marcador que nenhuma das outras regras casa. Sem isso, um `**` dentro de
/// `` `a**b` `` viraria negrito e o conteúdo do código sairia mutilado.
String _inline(String origem) {
  final guardados = <String>[];
  var texto = origem;

  // O marcador usa NUL nas pontas: nenhum texto de resposta traz esse
  // byte, então a restauração não casa com conteúdo de verdade.
  String guardar(String valor) {
    guardados.add(valor);
    return '\u0000${guardados.length - 1}\u0000';
  }

  for (final span in mathSpans(texto).reversed) {
    final convertido = latexRuns(span.latex).map((r) => r.text).join();
    texto = texto.replaceRange(span.inicio, span.fim, guardar(convertido));
  }
  texto = texto.replaceAllMapped(_codigo, (m) => guardar(m[2]!));

  texto = texto.replaceAllMapped(
    _imagem,
    (m) => _comEndereco(m[1]!.trim(), m[2]!.trim()),
  );
  texto = texto.replaceAllMapped(
    _link,
    (m) => _comEndereco(m[1]!.trim(), m[2]!.trim()),
  );
  for (final marca in _enfases) {
    texto = texto.replaceAllMapped(marca, (m) => m[1]!);
  }

  for (var i = guardados.length - 1; i >= 0; i--) {
    texto = texto.replaceAll('\u0000$i\u0000', guardados[i]);
  }
  return texto;
}

/// `rótulo (url)`, ou só o endereço quando o rótulo já é o endereço.
String _comEndereco(String rotulo, String url) {
  final alvo = url.split(RegExp(r'\s+')).first;
  if (rotulo.isEmpty) return alvo;
  if (rotulo == alvo) return alvo;
  return '$rotulo ($alvo)';
}

final RegExp _cerca = RegExp(r'^\s*```');
final RegExp _regraHorizontal = RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$');
final RegExp _separadorDeTabela = RegExp(r'^\s*\|?[\s:|-]*-[\s:|-]*\|[\s:|-]*$');
final RegExp _linhaDeTabela = RegExp(r'^\s*\|.*\|\s*$');
final RegExp _titulo = RegExp(r'^\s{0,3}#{1,6}\s+');
final RegExp _citacao = RegExp(r'^\s*>\s?');
final RegExp _tarefa = RegExp(r'^(\s*)[-*+]\s+\[([ xX])\]\s+');
final RegExp _bala = RegExp(r'^(\s*)[-*+]\s+');
final RegExp _codigo = RegExp(r'(`+)([^`]+?)\1');
final RegExp _imagem = RegExp(r'!\[([^\]]*)\]\(([^)]*)\)');
final RegExp _link = RegExp(r'\[([^\]]*)\]\(([^)]*)\)');

/// Ordem importa: o mais longo primeiro, senão `***x***` vira `*x*`.
///
/// O sublinhado só conta como ênfase colado a limite de palavra. Sem essa
/// guarda, `run_stop` e `session_id` perderiam o meio, e nome com sublinhado
/// aparece o tempo todo numa resposta técnica.
final List<RegExp> _enfases = [
  RegExp(r'\*\*\*(.+?)\*\*\*'),
  RegExp(r'\*\*(.+?)\*\*'),
  RegExp(r'\*(.+?)\*'),
  RegExp(r'~~(.+?)~~'),
  RegExp(r'(?<![\w\\])___(\S(?:.*?\S)?)___(?!\w)'),
  RegExp(r'(?<![\w\\])__(\S(?:.*?\S)?)__(?!\w)'),
  RegExp(r'(?<![\w\\])_(\S(?:.*?\S)?)_(?!\w)'),
];
