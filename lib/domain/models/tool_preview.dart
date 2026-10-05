import 'dart:convert';

/// Resume o argumento de uma ferramenta **do mesmo jeito** que o Hermes resume
/// ao vivo.
///
/// O problema que isto resolve, observado no aparelho: a mesma chamada aparece
/// de duas formas conforme a origem. Durante a run vem o `preview` que o
/// servidor calcula (`date`, `uptime`, `a.dart L1-45`); no histórico vem o
/// `arguments` cru do `tool_calls`
/// (`{"command":"date","workdir":"/home/operator…`). É o mesmo componente mostrando
/// a mesma chamada de dois jeitos, e o cru é ilegível numa linha.
///
/// Regra medida em `agent/display.py` da versão `0.19.0`, em
/// `build_tool_preview` e `summarize_shell_command`, que é a função que produz
/// o `preview` mandado no `tool.started`. O objetivo aqui é **empatar** com ela,
/// não inventar um formato melhor: dois formatos para a mesma chamada é
/// exatamente o defeito. Por isso os textos derivados ficam em inglês, como os
/// do servidor (`planning 3 task(s)`, `+ 2 commands`).
///
/// **Divergência deliberada, e é de segurança.** O caminho ao vivo passa por
/// `redact_tool_args_for_display`, que mascara o `text` de `browser_type` com o
/// redator de segredos do servidor. O `arguments` **persistido** é o cru, sem
/// redação, e o app não tem como redigir: não conhece os padrões e não deve
/// tentar adivinhá-los. Então, para `browser_type`, o histórico mostra a
/// ferramenta **sem argumento** em vez de arriscar exibir uma credencial que o
/// caminho ao vivo teria escondido.
String toolPreview(String toolName, String rawArguments) {
  final flat = _oneline(rawArguments);
  if (flat.isEmpty || flat == '{}') return '';

  Object? decoded;
  try {
    decoded = jsonDecode(rawArguments);
  } catch (_) {
    decoded = null;
  }
  if (decoded is! Map) {
    // Sem JSON legível não há chave primária para escolher; melhor a linha crua
    // encurtada do que nada.
    return _truncate(flat, 120);
  }
  final args = decoded.map((key, value) => MapEntry(key.toString(), value));
  return _truncate(_previewFrom(toolName, args) ?? '', 120);
}

/// Entrada completa que pode ser exibida sob gesto explícito.
///
/// Só terminal e execução de código entram aqui. Para as demais ferramentas o
/// payload persistido pode conter texto sensível que o servidor redige no
/// preview ao vivo; sem o mesmo redator, o app não expõe o argumento cru.
String toolDetail(String toolName, String rawArguments) {
  if (toolName != 'terminal' && toolName != 'execute_code') return '';

  Object? decoded;
  try {
    decoded = jsonDecode(rawArguments);
  } catch (_) {
    return '';
  }
  if (decoded is! Map) return '';
  final key = toolName == 'terminal' ? 'command' : 'code';
  final value = decoded[key];
  if (value is! String) return '';
  return value.trim();
}

/// Nunca mostramos o argumento cru destas ferramentas: o servidor o redige
/// antes de exibir, e o histórico guarda a versão sem redação.
const _redigidasPeloServidor = {'browser_type'};

/// Chave que representa a chamada, por ferramenta. Tabela `primary_args` de
/// `build_tool_preview`.
const _chavePrimaria = {
  'terminal': 'command',
  'web_search': 'query',
  'web_extract': 'urls',
  'read_file': 'path',
  'write_file': 'path',
  'patch': 'path',
  'search_files': 'pattern',
  'browser_navigate': 'url',
  'browser_click': 'ref',
  'browser_type': 'text',
  'image_generate': 'prompt',
  'text_to_speech': 'text',
  'vision_analyze': 'question',
  'skill_view': 'name',
  'skills_list': 'category',
  'cronjob': 'action',
  'execute_code': 'code',
  'delegate_task': 'goal',
  'clarify': 'question',
  'skill_manage': 'name',
};

const _chavesDeReserva = [
  'query',
  'text',
  'command',
  'path',
  'name',
  'prompt',
  'code',
  'goal',
];

String? _previewFrom(String tool, Map<String, Object?> args) {
  if (args.isEmpty) return null;
  if (_redigidasPeloServidor.contains(tool)) return null;

  switch (tool) {
    case 'delegate_task':
      final tasks = args['tasks'];
      if (tasks is List && tasks.isNotEmpty) {
        final goals = [
          for (final task in tasks)
            if (task is Map)
              _truncate(_oneline((task['goal'] ?? '?').toString()), 40)
            else
              '?',
        ];
        return '${goals.length} tasks: ${goals.join(' | ')}';
      }
      return _valorSimples(args['goal']);

    case 'todo':
      final todos = args['todos'];
      if (todos == null) return 'reading task list';
      final quantos = todos is List ? todos.length : 1;
      final merge = args['merge'] == true;
      return merge ? 'updating $quantos task(s)' : 'planning $quantos task(s)';

    case 'terminal':
    case 'execute_code':
      final bruto = args[tool == 'execute_code' ? 'code' : 'command'];
      if (bruto == null) return null;
      final resumo = summarizeShellCommand(bruto.toString());
      return resumo.isEmpty ? null : resumo;

    case 'read_file':
      final path = args['path'] ?? args['file'] ?? args['filepath'];
      if (path == null) return null;
      final nome = path.toString().replaceAll('\\', '/').split('/').last;
      final rotulo = _rotuloDeLinhas(args);
      return '${nome.isEmpty ? path : nome} $rotulo'.trim();

    case 'session_search':
      final query = _oneline((args['query'] ?? '').toString());
      return 'recall: "${query.length > 25 ? '${query.substring(0, 25)}...' : query}"';

    case 'memory':
      return _memoria(args);

    case 'send_message':
      final alvo = args['target'] ?? '?';
      var msg = _oneline((args['message'] ?? '').toString());
      if (msg.length > 20) msg = '${msg.substring(0, 17)}...';
      return 'to $alvo: "$msg"';

    case 'skill_view':
      final nome = _oneline((args['name'] ?? '').toString());
      final arquivo = args['file_path'];
      if (arquivo != null) {
        final caminho = _oneline(arquivo.toString());
        return nome.isEmpty ? caminho : '$nome → $caminho';
      }
      return nome.isEmpty ? null : nome;
  }

  var chave = _chavePrimaria[tool];
  if (chave == null) {
    for (final reserva in _chavesDeReserva) {
      if (args.containsKey(reserva)) {
        chave = reserva;
        break;
      }
    }
  }
  if (chave == null || !args.containsKey(chave)) return null;
  return _valorSimples(args[chave]);
}

String? _valorSimples(Object? valor) {
  if (valor == null) return null;
  final escolhido = valor is List ? (valor.isEmpty ? '' : valor.first) : valor;
  final texto = _oneline(escolhido.toString());
  return texto.isEmpty ? null : texto;
}

String _memoria(Map<String, Object?> args) {
  final acao = (args['action'] ?? '').toString();
  final alvo = (args['target'] ?? '').toString();
  String recorte(Object? valor, int limite) {
    final texto = _oneline((valor ?? '').toString());
    return texto.length > limite ? '${texto.substring(0, limite)}...' : texto;
  }

  switch (acao) {
    case 'add':
      return '+$alvo: "${recorte(args['content'], 25)}"';
    case 'replace':
      final velho = _oneline((args['old_text'] ?? '').toString());
      return '~$alvo: "${velho.isEmpty ? '<missing old_text>' : recorte(velho, 20)}"';
    case 'remove':
      final velho = _oneline((args['old_text'] ?? '').toString());
      return '-$alvo: "${velho.isEmpty ? '<missing old_text>' : recorte(velho, 20)}"';
  }
  return acao;
}

String _rotuloDeLinhas(Map<String, Object?> args) {
  final offset = args['offset'];
  final limit = args['limit'];
  if (offset is! int || offset <= 0) return '';
  if (limit is! int || limit <= 1) return 'L$offset';
  return 'L$offset-${offset + limit - 1}';
}

/// Porta de `summarize_shell_command`: encolhe encanamento de shell sem mexer
/// no comando de verdade, que continua guardado no servidor.
String summarizeShellCommand(String command) {
  final original = _oneline(command);
  if (original.isEmpty) return '';

  final segmentos = _dividirCompound(original);
  if (segmentos.length <= 1) {
    final limpo = _limparSegmento(
      segmentos.isEmpty ? original : segmentos.first,
    );
    return limpo.isEmpty ? original : limpo;
  }

  final nucleo = <String>[];
  for (final segmento in segmentos) {
    final limpo = _limparSegmento(segmento);
    final cabeca = _cabecaDoSegmento(limpo);
    if (limpo.isNotEmpty &&
        !_cabecasSilenciosas.contains(cabeca) &&
        !_ecoDeFronteira(limpo)) {
      nucleo.add(limpo);
    }
  }

  if (nucleo.isEmpty) return original;
  if (nucleo.length == 1) return nucleo.first;
  final restantes = nucleo.length - 1;
  return '${nucleo.first} + $restantes ${restantes == 1 ? 'command' : 'commands'}';
}

const _cabecasSilenciosas = {
  'cd',
  'pushd',
  'popd',
  'export',
  'set',
  'unset',
  'source',
  '.',
  'true',
  'false',
  ':',
};
const _caudasDeCano = {'head', 'tail', 'wc', 'sort', 'uniq'};

List<String> _dividirPalavras(String segmento) {
  final palavras = <String>[];
  final buffer = StringBuffer();
  String? aspa;

  for (var i = 0; i < segmento.length; i++) {
    final ch = segmento[i];
    if (aspa != null) {
      buffer.write(ch);
      if (ch == aspa && (i == 0 || segmento[i - 1] != r'\')) aspa = null;
      continue;
    }
    if (ch == "'" || ch == '"') {
      aspa = ch;
      buffer.write(ch);
      continue;
    }
    if (ch.trim().isEmpty) {
      if (buffer.isNotEmpty) {
        palavras.add(buffer.toString());
        buffer.clear();
      }
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) palavras.add(buffer.toString());
  return palavras;
}

String _base(String palavra) => palavra.isEmpty ? '' : palavra.split('/').last;

String _cortarCaudaDeCano(String segmento) {
  final palavras = _dividirPalavras(segmento);
  final saida = <String>[];
  for (var i = 0; i < palavras.length; i++) {
    final palavra = palavras[i];
    final proxima = i + 1 < palavras.length ? palavras[i + 1] : '';
    if (palavra == '|' && _caudasDeCano.contains(_base(proxima))) break;
    saida.add(palavra);
  }
  return saida.join(' ').trim();
}

List<String> _dividirCompound(String command) {
  final segmentos = <String>[];
  final buffer = StringBuffer();
  String? aspa;
  var i = 0;

  void fechar() {
    final segmento = _cortarCaudaDeCano(buffer.toString().trim());
    if (segmento.isNotEmpty) segmentos.add(segmento);
    buffer.clear();
  }

  while (i < command.length) {
    final ch = command[i];
    if (aspa != null) {
      buffer.write(ch);
      if (ch == aspa && (i == 0 || command[i - 1] != r'\')) aspa = null;
      i++;
      continue;
    }
    if (ch == "'" || ch == '"') {
      aspa = ch;
      buffer.write(ch);
      i++;
      continue;
    }
    final duplo = command.startsWith('&&', i) || command.startsWith('||', i);
    final tamanho = duplo ? 2 : (ch == ';' || ch == '\n' ? 1 : 0);
    if (tamanho > 0) {
      fechar();
      i += tamanho;
      continue;
    }
    buffer.write(ch);
    i++;
  }
  fechar();
  return segmentos;
}

final _atribuicao = RegExp(r'^[A-Za-z_]\w*=');
final _redirecionamentoComAlvo = RegExp(r'^\d*(?:>>?|<)$');
final _redirecionamentoDeDescritor = RegExp(r'^\d*(?:>&|<&)\d+$');
final _marcaDeFronteira = RegExp(r'-{2,}|_exit=|(?:^|\s|=)\$[?{]|PIPESTATUS');

String _cabecaDoSegmento(String segmento) {
  final palavras = _dividirPalavras(segmento);
  var index = 0;
  while (index < palavras.length && _atribuicao.hasMatch(palavras[index])) {
    index++;
  }
  return _base(index < palavras.length ? palavras[index] : '');
}

String _limparSegmento(String segmento) {
  final palavras = _dividirPalavras(segmento);
  final saida = <String>[];
  var i = 0;
  while (i < palavras.length) {
    final palavra = palavras[i];
    if (_redirecionamentoComAlvo.hasMatch(palavra)) {
      i += 2;
      continue;
    }
    if (_redirecionamentoDeDescritor.hasMatch(palavra)) {
      i += 1;
      continue;
    }
    saida.add(palavra);
    i++;
  }
  return saida.join(' ').trim();
}

bool _ecoDeFronteira(String segmento) {
  final palavras = _dividirPalavras(segmento);
  if (_base(palavras.isEmpty ? '' : palavras.first) != 'echo') return false;
  return _marcaDeFronteira.hasMatch(palavras.skip(1).join(' '));
}

String _oneline(String texto) =>
    texto.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).join(' ');

String _truncate(String texto, int max) {
  if (max <= 0 || texto.length <= max) return texto;
  if (max <= 3) return '.' * max;
  return '${texto.substring(0, max - 3)}...';
}
