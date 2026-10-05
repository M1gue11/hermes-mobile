import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/models/run_event.dart';
import '../../domain/models/turn_activity.dart';

/// Captura redigida de um turno, para fechar o diagnóstico de A58/A59.
///
/// O app monta a mesma resposta por dois caminhos que nunca se encontram: a
/// projeção **ao vivo** (frame -> adapter -> reducer) e a projeção **reaberta**
/// (`session.history` -> `conversationTimeline`). Comparar as duas a olho, na
/// tela, não separa perda de contrato de perda de código. Esta captura observa
/// as quatro camadas no mesmo turno e emite o veredito automaticamente.
///
/// Regra de segredo: por padrão nenhum valor de texto sai daqui. O relatório
/// carrega somente nome de evento, nome de campo, id encurtado, ordem e
/// tamanho (`142ch`). Chave com cara de credencial vira `<redigido>` mesmo com
/// amostra ligada. A captura é `kDebugMode`, vive só em memória e nunca é
/// escrita em disco pelo app.
final turnCapture = TurnCapture();

/// Camada onde o acontecimento foi observado.
enum CaptureLayer {
  /// Frame cru do gateway ou do SSE, antes de qualquer interpretação.
  transporte,

  /// [RunEvent] produzido pelo adapter.
  adapter,

  /// Chamada RPC saindo do aparelho.
  saida,
}

class CaptureEntry {
  const CaptureEntry({
    required this.at,
    required this.layer,
    required this.label,
    required this.fields,
  });

  final Duration at;
  final CaptureLayer layer;
  final String label;
  final Map<String, String> fields;
}

/// Uma projeção de turno já reduzida a shapes comparáveis.
class CaptureProjection {
  const CaptureProjection(this.items);

  final List<TurnActivity> items;

  int get tools => items.whereType<TurnToolActivity>().length;
  int get reasoning => items.whereType<TurnReasoning>().length;
  int get previews => items.whereType<TurnActivityPreview>().length;
}

class TurnCapture extends ChangeNotifier {
  /// Um turno longo com muitas ferramentas cabe folgado; o teto existe só para
  /// que uma sessão esquecida ligada não cresça sem limite.
  static const maxEntries = 3000;

  final _entries = <CaptureEntry>[];
  final _stopwatch = Stopwatch();

  final _rawTypes = <String, int>{};
  final _adapterKinds = <String, int>{};
  final _progressWithId = <String>[];
  var _progressWithoutId = 0;
  final _startDetailLength = <String, int>{};

  /// Qual transporte produziu os frames. Um turno que abre o socket do TUI e
  /// mesmo assim recebe evento de Runs caiu no fallback, e isso muda a leitura
  /// de todo o resto do relatório.
  var _tuiFrames = 0;
  var _runsFrames = 0;

  /// Correlação de ferramenta: sem id, o cliente casa abertura e conclusão por
  /// FIFO de nome. Duas chamadas simultâneas do mesmo nome quebram esse casamento.
  var _startsWithId = 0;
  var _startsWithoutId = 0;
  final _rpcFailures = <String>[];

  /// Guardados só para comparar entre si; nenhum dos dois é impresso.
  final _previewTexts = <String>[];
  String? _completedOutput;
  final _openByName = <String, int>{};
  final _peakByName = <String, int>{};

  var _armed = false;
  var _sampleText = false;
  var _capturing = false;
  var _began = false;
  var _origin = '';
  var _session = '';
  var _outcome = '';

  CaptureProjection? _live;
  CaptureProjection? _history;
  String? _lastFallback;

  /// Capturar o próximo turno enviado ou retomado.
  bool get armed => _armed;

  /// Incluir uma amostra de 80 caracteres nos campos de texto.
  bool get sampleText => _sampleText;

  /// Há um turno sendo observado agora.
  bool get capturing => _capturing;

  bool get hasCapture =>
      _entries.isNotEmpty || _live != null || _history != null;

  List<CaptureEntry> get entries => List.unmodifiable(_entries);

  /// Por que o último turno não correu pelo Dashboard TUI, ou `null` se correu.
  ///
  /// A67: a queda para a Runs API era **muda**. Nada na tela, no log ou na
  /// captura dizia que o transporte tinha caído, e foi por isso que o TUI
  /// passou semanas sem nunca ter sido exercitado de verdade no aparelho.
  String? get lastFallbackReason => _lastFallback;

  void arm(bool value) {
    if (!kDebugMode || _armed == value) return;
    _armed = value;
    notifyListeners();
  }

  void setSampleText(bool value) {
    if (!kDebugMode || _sampleText == value) return;
    _sampleText = value;
    notifyListeners();
  }

  void clear() {
    if (!kDebugMode) return;
    _entries.clear();
    _rawTypes.clear();
    _adapterKinds.clear();
    _progressWithId.clear();
    _startDetailLength.clear();
    _openByName.clear();
    _peakByName.clear();
    _rpcFailures.clear();
    _previewTexts.clear();
    _completedOutput = null;
    _progressWithoutId = 0;
    _tuiFrames = 0;
    _runsFrames = 0;
    _startsWithId = 0;
    _startsWithoutId = 0;
    _live = null;
    _history = null;
    _outcome = '';
    _capturing = false;
    _began = false;
    _stopwatch
      ..stop()
      ..reset();
    notifyListeners();
  }

  /// Arma a observação de um turno. Só age se a pessoa ligou a captura, e
  /// desarma em seguida: cada gesto na tela de debug vale por um turno, para
  /// que um turno pareado com outro não misture dois diagnósticos.
  void beginTurn({required String sessionId, required String origin}) {
    if (!kDebugMode || !_armed) return;
    clear();
    _armed = false;
    _capturing = true;
    _began = true;
    _origin = origin;
    _session = _shortId(sessionId);
    _fullSession = sessionId;
    _stopwatch
      ..reset()
      ..start();
    notifyListeners();
  }

  void endTurn(String outcome) {
    if (!kDebugMode || !_capturing) return;
    _capturing = false;
    _outcome = outcome;
    _stopwatch.stop();
    notifyListeners();
  }

  /// Chamada RPC saindo. Só o nome do método e os nomes dos parâmetros: o corpo
  /// de `file.attach` carrega o anexo inteiro em base64.
  void outgoing(String method, Map<String, dynamic> params) {
    if (!_recording) return;
    _add(CaptureLayer.saida, method, {
      for (final key in params.keys) key: _render(key, params[key]),
    });
  }

  /// Resposta de uma chamada RPC. Sem isto a captura não explica por que um
  /// turno que abriu o socket do TUI acabou correndo pela Runs API: a recusa
  /// vive na resposta da chamada, não no fluxo de eventos.
  void rpcResult(String method, Map<String, dynamic> result) {
    if (!_recording) return;
    _add(CaptureLayer.saida, 'ok $method', {
      for (final key in result.keys) key: _render(key, result[key]),
    });
  }

  /// O turno desistiu do Dashboard TUI e vai correr pela Runs API.
  ///
  /// [reason] é um motivo fixo escolhido no ponto da queda, nunca conteúdo da
  /// conversa. Vale em debug mesmo sem captura armada: o valor da correção é
  /// justamente aparecer quando ninguém está medindo.
  void transportFallback(String reason) {
    if (!kDebugMode) return;
    _lastFallback = reason;
    debugPrint('[hermes] transporte caiu para a Runs API: $reason');
    if (_recording) _add(CaptureLayer.saida, 'FALLBACK', {'motivo': reason});
    notifyListeners();
  }

  /// O turno de fato correu pelo Dashboard TUI, então não há queda a anunciar.
  void transportHeld() {
    if (!kDebugMode || _lastFallback == null) return;
    _lastFallback = null;
    notifyListeners();
  }

  void rpcError(String method, int code, String message) {
    if (!_recording) return;
    _rpcFailures.add('$method($code)');
    _add(CaptureLayer.saida, 'ERRO $method', {
      'code': '$code',
      'message': _render('message', message),
    });
  }

  /// Frame de evento do gateway TUI, antes de `_eventsFrom`.
  void rawFrame(String type, Map<String, dynamic> payload) {
    if (!_recording) return;
    _tuiFrames++;
    _rawTypes[type] = (_rawTypes[type] ?? 0) + 1;
    _noteToolShape(type, payload);
    _add(CaptureLayer.transporte, type, {
      for (final key in payload.keys) key: _render(key, payload[key]),
    });
  }

  /// Frame SSE da Runs API, antes de `parseSse`.
  void rawSse(String? event, String data) {
    if (!_recording) return;
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(data.trim());
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // Frame não-JSON continua valendo pelo tamanho.
    }
    final type = (event ?? json?['event'] ?? json?['type'] ?? 'sem-tipo')
        .toString();
    _runsFrames++;
    _rawTypes[type] = (_rawTypes[type] ?? 0) + 1;
    if (json != null) _noteToolShape(type, json);
    _add(CaptureLayer.transporte, type, {
      if (json == null)
        'data': _render('data', data)
      else
        for (final key in json.keys) key: _render(key, json[key]),
    });
  }

  /// [RunEvent] que o adapter entregou ao reducer.
  void adapterEvent(RunEvent event) {
    if (!_recording) return;
    final (label, fields) = switch (event) {
      RunActivityPreview(:final text) => ('activityPreview', {'text': text}),
      RunReasoningDelta(:final text) => ('reasoningDelta', {'text': text}),
      RunThinkingState(:final text) => ('thinkingState', {'text': text}),
      RunTextDelta(:final text) => ('delta', {'text': text}),
      RunToolProgress(:final tool) => (
        'toolProgress',
        <String, Object?>{
          'name': tool.name,
          'tool_id': tool.id,
          'status': tool.status.name,
          'arg': tool.arg,
          'detail': tool.detail,
          'output': tool.output,
          'duration': tool.duration,
        },
      ),
      RunApprovalRequest(:final request) => (
        'approvalRequest',
        <String, Object?>{'command': request.command},
      ),
      RunApprovalResolved(:final choice) => (
        'approvalResolved',
        <String, Object?>{'choice': choice.name},
      ),
      RunClarifyRequest(:final request) => (
        'clarifyRequest',
        <String, Object?>{'questions': request.questions.length},
      ),
      RunClarifyResolved() => ('clarifyResolved', <String, Object?>{}),
      RunStatusEvent(:final status) => (
        'status',
        <String, Object?>{'status': status.name},
      ),
      RunCompleted(:final output) => (
        'completed',
        <String, Object?>{'output': output},
      ),
      RunFailed(:final error) => ('failed', <String, Object?>{'error': error}),
      RunUnknown(:final type, :final data) => (
        'unknown:$type',
        <String, Object?>{for (final key in data.keys) key: data[key]},
      ),
    };
    switch (event) {
      case RunActivityPreview(:final text):
        _previewTexts.add(text);
      case RunCompleted(:final output):
        if (output != null && output.isNotEmpty) _completedOutput = output;
      default:
        break;
    }
    _adapterKinds[label] = (_adapterKinds[label] ?? 0) + 1;
    _add(CaptureLayer.adapter, label, {
      for (final key in fields.keys) key: _render(key, fields[key]),
    });
  }

  /// Projeção montada pelo stream, lida do estado no fim do turno.
  void liveProjection(List<TurnActivity> items) {
    if (!_recording) return;
    _live = CaptureProjection(List.of(items));
    notifyListeners();
  }

  /// Resultado da sonda de contrato, guardado fora do ciclo de um turno.
  ///
  /// A sonda existe para responder uma pergunta que a captura de turno não
  /// alcança: quando `session.resume` recusa, o resto do gateway está de pé?
  /// Por isso ela sobrevive a `clear()` de turno e aparece no topo do relatório.
  List<String> get probe => List.unmodifiable(_probe);
  final _probe = <String>[];

  /// Sessão do último turno observado, para a sonda repetir o mesmo alvo.
  /// Não é segredo e já aparece encurtada no relatório; aqui vai inteira porque
  /// é parâmetro de RPC, não texto de saída.
  String? get lastSessionId => _fullSession;
  String? _fullSession;

  void setProbe(Iterable<String> steps) {
    if (!kDebugMode) return;
    _probe
      ..clear()
      ..addAll(steps);
    notifyListeners();
  }

  /// Mesma projeção reconstruída por `conversationTimeline`, do histórico.
  ///
  /// Chega depois de `endTurn` no caminho real, porque buscar o histórico é
  /// assíncrono. Por isso a guarda é o turno ter começado, não ele ainda estar
  /// aberto: sem isso a comparação nunca teria o outro lado.
  void historyProjection(List<TurnActivity> items) {
    if (!kDebugMode || !_began) return;
    _history = CaptureProjection(List.of(items));
    notifyListeners();
  }

  bool get _recording => kDebugMode && _capturing;

  void _add(CaptureLayer layer, String label, Map<String, String> fields) {
    if (_entries.length >= maxEntries) return;
    _entries.add(
      CaptureEntry(
        at: _stopwatch.elapsed,
        layer: layer,
        label: label,
        fields: fields,
      ),
    );
    notifyListeners();
  }

  /// Guarda o que as perguntas do diagnóstico precisam medir.
  void _noteToolShape(String type, Map<String, dynamic> payload) {
    String? idOf(Map<String, dynamic> data) {
      final raw = (data['tool_id'] ?? data['tool_call_id'] ?? data['call_id'])
          ?.toString();
      return raw == null || raw.isEmpty ? null : raw;
    }

    String nameOf(Map<String, dynamic> data) =>
        (data['name'] ?? data['tool'] ?? data['tool_name'])?.toString() ?? '?';

    switch (type) {
      case 'tool.progress' || 'tool.generating':
        final id = idOf(payload);
        if (id == null) {
          _progressWithoutId++;
        } else {
          _progressWithId.add(id);
        }
      case 'tool.start' || 'tool.started':
        final name = nameOf(payload);
        if (idOf(payload) == null) {
          _startsWithoutId++;
        } else {
          _startsWithId++;
        }
        final open = (_openByName[name] ?? 0) + 1;
        _openByName[name] = open;
        if (open > (_peakByName[name] ?? 0)) _peakByName[name] = open;
        final args = payload['args_text']?.toString();
        if (args != null) _startDetailLength[idOf(payload) ?? name] = args.length;
      case 'tool.complete' || 'tool.completed':
        final name = nameOf(payload);
        final open = (_openByName[name] ?? 0) - 1;
        _openByName[name] = open < 0 ? 0 : open;
    }
  }

  // --- redação ---------------------------------------------------------------

  static const _secretHints = <String>[
    'password',
    'senha',
    'token',
    'ticket',
    'cookie',
    'authorization',
    'secret',
    'bearer',
    'api_key',
    'apikey',
    'credential',
    'private_key',
  ];

  /// Campos cujo valor literal é o próprio dado do diagnóstico.
  static const _literal = <String>{
    'type',
    'event',
    'name',
    'status',
    'role',
    'phase',
    'provider',
    'model',
    'source',
    'index',
    'done',
    'duration',
    'duration_s',
    'choice',
    'kind',
    'state',
  };

  /// Campos que são identificadores: aparecem encurtados, nunca inteiros.
  static const _identifier = <String>{
    'id',
    'tool_id',
    'tool_call_id',
    'call_id',
    'session_id',
    'request_id',
    'run_id',
    'turn_id',
    'message_id',
    'parent_id',
    'subagent_id',
  };

  String _render(String key, Object? value) {
    final normalized = key.toLowerCase();
    if (_secretHints.any(normalized.contains)) return '<redigido>';
    if (value == null) return '-';
    if (value is bool || value is num) return '$value';
    if (value is List) return '[${value.length}]';
    if (value is Map) {
      final keys = value.keys.take(8).join(',');
      return value.length > 8 ? '{$keys,…}' : '{$keys}';
    }
    final text = value.toString();
    if (text.isEmpty) return 'vazio';
    if (_identifier.contains(normalized)) return _shortId(text);
    if (_literal.contains(normalized)) {
      return text.length <= 48 ? text : '${text.substring(0, 48)}…';
    }
    return _sampleText ? '${text.length}ch «${_oneLine(text, 80)}»' : '${text.length}ch';
  }

  static String _shortId(String value) =>
      value.length <= 10 ? value : '…${value.substring(value.length - 8)}';

  static String _oneLine(String value, int limit) {
    final flat = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= limit ? flat : '${flat.substring(0, limit)}…';
  }

  // --- relatório -------------------------------------------------------------

  /// Texto pronto para copiar. Já redigido: pode ir para o backlog e para o
  /// vault sem passar por revisão de segredo.
  String report() {
    if (_entries.isEmpty && _probe.isEmpty) {
      return 'Nenhuma captura. Ligue e envie uma pergunta, ou sonde o gateway.';
    }
    if (_entries.isEmpty) return _probeSection();
    final out = StringBuffer()
      ..writeln('CAPTURA DE TURNO  origem=$_origin  sessão=$_session')
      ..writeln(
        'entradas=${_entries.length}  duração=${_ms(_stopwatch.elapsed)}  '
        'estado=${_capturing ? "em curso" : (_outcome.isEmpty ? "parada" : _outcome)}',
      )
      ..writeln(
        'transporte: frames TUI=$_tuiFrames  frames Runs=$_runsFrames  '
        '-> ${_transportLabel()}',
      )
      ..writeln(
        'redação=${_sampleText ? "shapes + amostra de 80ch" : "somente shapes"}',
      )
      ..writeln();

    if (_probe.isNotEmpty) out.write(_probeSection());

    // O veredito vem primeiro porque é a razão da captura existir. O diário de
    // frames é longo por natureza e empurrava a conclusão para fora de qualquer
    // colagem.
    out.writeln('VEREDITO');
    for (final line in verdict()) {
      out.writeln('  $line');
    }
    out.writeln();

    _projection(out, 'PROJEÇÃO AO VIVO (fim do turno)', _live);
    _projection(out, 'PROJEÇÃO DO HISTÓRICO (mesmo turno)', _history);

    _census(out, 'CENSO DE FRAMES', _rawTypes);
    _census(out, 'CENSO DE RunEvent', _adapterKinds);

    _section(out, 'SAÍDA (RPC do aparelho)', CaptureLayer.saida);
    _section(out, 'TRANSPORTE (frame cru)', CaptureLayer.transporte);
    _section(out, 'ADAPTER (RunEvent)', CaptureLayer.adapter);

    return out.toString();
  }

  /// Lê a sonda e diz o que ela separou.
  String _probeSection() {
    final out = StringBuffer()..writeln('SONDA DO GATEWAY (${_probe.length})');
    for (final step in _probe) {
      out.writeln('  $step');
    }
    final leitura = _probe.where(
      (step) => step.contains('session.list') || step.contains('session.history'),
    );
    final resume = _probe.where((step) => step.contains('session.resume'));
    if (leitura.isNotEmpty && resume.isNotEmpty) {
      final leituraOk = leitura.every((step) => step.startsWith('ok'));
      final resumeOk = resume.every((step) => step.startsWith('ok'));
      out.writeln(
        '  -> ${switch ((leituraOk, resumeOk)) {
          (true, true) => 'gateway íntegro; o fallback tem outra causa',
          (true, false) =>
            'o SessionDB responde e só session.resume recusa: '
                'a falha é do resume, não do banco',
          (false, false) =>
            'leitura e resume recusam igual: a conexão do banco morreu '
                'no processo do gateway',
          (false, true) => 'resultado incoerente; repetir a sonda',
        }}',
      );
    }
    return (out..writeln()).toString();
  }

  String _transportLabel() {
    if (_tuiFrames > 0 && _runsFrames > 0) {
      final causa = _rpcFailures.isEmpty
          ? 'nenhum RPC recusou; ver a seção SAÍDA'
          : 'recusa em ${_rpcFailures.join(", ")}';
      return 'FALLBACK: o socket do TUI abriu e o turno correu pela Runs API '
          '($causa)';
    }
    if (_runsFrames > 0) return 'Runs API';
    if (_tuiFrames > 0) return 'Dashboard TUI';
    return 'nenhum frame';
  }

  void _census(StringBuffer out, String title, Map<String, int> counts) {
    if (counts.isEmpty) return;
    final ordered = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    out
      ..writeln('$title  (${ordered.length} tipos)')
      ..writeln(
        '  ${ordered.map((e) => "${e.key}=${e.value}").join("  ")}',
      )
      ..writeln();
  }

  /// Colapsa repetição consecutiva do mesmo rótulo.
  ///
  /// Um turno real emite centenas de `message.delta`, e listar um por linha
  /// afoga tudo que interessa. A linha agregada preserva o que a leitura precisa:
  /// quantos, em que janela, e a forma do primeiro e do último.
  void _section(StringBuffer out, String title, CaptureLayer layer) {
    final rows = _entries.where((entry) => entry.layer == layer).toList();
    if (rows.isEmpty) return;
    out.writeln('$title  (${rows.length})');
    var index = 0;
    while (index < rows.length) {
      final first = rows[index];
      var last = index;
      while (last + 1 < rows.length && rows[last + 1].label == first.label) {
        last++;
      }
      final repeats = last - index + 1;
      if (repeats == 1) {
        out.writeln('  ${_ms(first.at).padLeft(8)}  ${first.label}  '
            '${_fieldsOf(first)}');
      } else {
        out
          ..writeln(
            '  ${_ms(first.at).padLeft(8)}..${_ms(rows[last].at)}  '
            '${first.label} x$repeats',
          )
          ..writeln('             primeiro: ${_fieldsOf(first)}')
          ..writeln('             último:   ${_fieldsOf(rows[last])}');
      }
      index = last + 1;
    }
    out.writeln();
  }

  static String _fieldsOf(CaptureEntry entry) => entry.fields.entries
      .map((field) => '${field.key}=${field.value}')
      .join('  ');

  void _projection(StringBuffer out, String title, CaptureProjection? shot) {
    if (shot == null) {
      out
        ..writeln('$title: não capturada')
        ..writeln();
      return;
    }
    out.writeln('$title  (${shot.items.length} blocos)');
    for (var index = 0; index < shot.items.length; index++) {
      out.writeln('  [$index] ${_activityLine(shot.items[index])}');
    }
    out.writeln();
  }

  String _activityLine(TurnActivity item) => switch (item) {
    TurnActivityPreview(:final text) =>
      'atividade  ${_render("text", text)}',
    TurnReasoning(:final text) => 'raciocínio  ${_render("text", text)}',
    TurnToolActivity(:final tool) => [
      'tool  ${tool.name}',
      'id=${_render("tool_id", tool.id)}',
      'status=${tool.status.name}',
      'arg=${_render("arg", tool.arg)}',
      'detail=${_render("detail", tool.detail)}',
      'output=${_render("output", tool.output)}',
    ].join('  '),
  };

  /// Responde, com o que foi medido, as perguntas que travam A59.
  List<String> verdict() {
    final lines = <String>[];

    // Q1: o resultado integral da ferramenta existe ao vivo?
    final pares = _pairTools();
    if (pares.isEmpty) {
      lines.add(
        'Q1 output integral ao vivo? INDETERMINADO '
        '(faltou projeção ao vivo ou do histórico com ferramenta)',
      );
    } else {
      final perdas = <String>[];
      for (final par in pares) {
        final vivo = par.live.output?.length ?? 0;
        final salvo = par.history.output?.length ?? 0;
        if (salvo > vivo) perdas.add('${par.live.name} ${vivo}ch<${salvo}ch');
      }
      lines.add(
        perdas.isEmpty
            ? 'Q1 output integral ao vivo? SIM (nenhuma tool cresce ao reabrir)'
            : 'Q1 output integral ao vivo? NÃO -> ${perdas.join(", ")}',
      );
    }

    // Q2: reasoning nativo incremental chega mesmo?
    final deltasCrus = _rawTypes['reasoning.delta'] ?? 0;
    final deltasAdapter = _adapterKinds['reasoningDelta'] ?? 0;
    final disponiveis = _rawTypes['reasoning.available'] ?? 0;
    lines.add(
      deltasCrus == 0
          ? 'Q2 reasoning.delta chega? NÃO '
                '(0 frames; reasoning.available=$disponiveis)'
          : 'Q2 reasoning.delta chega? SIM '
                '($deltasCrus frames, $deltasAdapter viraram RunEvent)',
    );

    // Q3: dá para correlacionar evento de ferramenta com o card certo?
    final progressos = _progressWithId.length + _progressWithoutId;
    final inicios = _startsWithId + _startsWithoutId;
    if (inicios == 0 && progressos == 0) {
      lines.add('Q3 correlação de ferramenta: SEM AMOSTRA (0 eventos)');
    } else {
      final paralelos = _peakByName.entries.where((e) => e.value > 1).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (inicios > 0) {
        // O aviso de paralelismo só vale quando falta id: com id, a correlação
        // é exata e duas chamadas simultâneas do mesmo nome não se confundem.
        final arriscado = _startsWithoutId > 0 && paralelos.isNotEmpty;
        lines.add(
          'Q3 abertura de ferramenta tem id? '
          '${_startsWithoutId == 0 ? "SIM" : (_startsWithId == 0 ? "NÃO" : "PARCIAL")} '
          '($_startsWithId/$inicios com id)'
          '${arriscado ? " | sem id o FIFO por nome não resolve paralelismo: "
              "${paralelos.map((e) => "${e.key} x${e.value}").join(", ")}" : ""}',
        );
      }
      if (progressos > 0) {
        lines.add(
          'Q3b tool.progress tem id? '
          '${_progressWithoutId == 0 ? "SIM" : "PARCIAL"} '
          '(${_progressWithId.length}/$progressos) | ATENÇÃO: medido no 0.20.1, '
          'o gateway não emite este evento. Ele saiu da allowlist, então isto '
          'aqui é contrato novo e precisa de decisão',
        );
      }
    }

    // Q4: o `summary` do complete apaga os argumentos do start?
    final sobrescritos = <String>[];
    for (final atual in _toolList(_live)) {
      final inicial =
          _startDetailLength[atual.id ?? ''] ?? _startDetailLength[atual.name];
      final agora = atual.detail?.length ?? 0;
      if (inicial != null && inicial > 0 && agora != inicial) {
        sobrescritos.add('${atual.name} ${inicial}ch->${agora}ch');
      }
    }
    lines.add(
      sobrescritos.isEmpty
          ? 'Q4 detail do start sobrevive ao complete? SIM'
          : 'Q4 detail do start sobrevive ao complete? NÃO -> '
                '${sobrescritos.join(", ")}',
    );

    // Q6: a prévia de atividade está repetindo a resposta final?
    //
    // Igualdade exata não basta: medido no TUI, a prévia veio com 501
    // caracteres e o `message.complete` com 716, ou seja, o mesmo texto
    // truncado. Comparar o começo é o que reconhece a duplicação real.
    final duplicadas = _previewTexts.where(_repeatsOutput).length;
    if (_completedOutput == null) {
      lines.add('Q6 prévia repete a resposta final? INDETERMINADO (sem output)');
    } else {
      lines.add(
        duplicadas == 0
            ? 'Q6 prévia repete a resposta final? NÃO'
            : 'Q6 prévia repete a resposta final? SIM -> $duplicadas prévia(s) '
                  'idêntica(s) ao output; a resposta aparece duas vezes na '
                  'timeline ao vivo',
      );
    }

    // Q7: o histórico guarda raciocínio que nunca chegou ao vivo?
    final vivoRaciocinio = _live?.reasoning ?? 0;
    final salvoRaciocinio = _history?.reasoning ?? 0;
    if (_live != null && _history != null && salvoRaciocinio > vivoRaciocinio) {
      lines.add(
        'Q7 raciocínio só no histórico? SIM -> $salvoRaciocinio bloco(s) '
        'persistido(s) contra $vivoRaciocinio ao vivo',
      );
    }

    // Q5: a mesma resposta tem a mesma forma nas duas projeções?
    final vivo = _live;
    final salvo = _history;
    if (vivo == null || salvo == null) {
      lines.add('Q5 blocos vivo x histórico: INDETERMINADO');
    } else {
      lines.add(
        'Q5 blocos vivo x histórico: '
        'tools ${vivo.tools}x${salvo.tools}  '
        'raciocínio ${vivo.reasoning}x${salvo.reasoning}  '
        'atividade ${vivo.previews}x${salvo.previews}',
      );
    }
    return lines;
  }

  /// Uma prévia repete a resposta quando as duas começam igual por um trecho
  /// longo o bastante para não ser coincidência de saudação.
  bool _repeatsOutput(String preview) {
    final output = _completedOutput;
    if (output == null || preview.isEmpty) return false;
    final a = _oneLine(preview, 120);
    final b = _oneLine(output, 120);
    if (a.isEmpty || b.isEmpty) return false;
    final limite = a.length < b.length ? a.length : b.length;
    if (limite < 40) return a == b;
    return a.substring(0, limite) == b.substring(0, limite);
  }

  List<_ToolShape> _toolList(CaptureProjection? shot) => [
    for (final item in shot?.items ?? const <TurnActivity>[])
      if (item is TurnToolActivity)
        _ToolShape(
          id: item.tool.id,
          name: item.tool.name,
          detail: item.tool.detail,
          output: item.tool.output,
        ),
  ];

  /// Casa a mesma ferramenta nas duas projeções.
  ///
  /// Casar só por id é o que fazia o comparador desistir em silêncio no caso
  /// mais importante: a Runs API não manda id ao vivo, o histórico manda, e as
  /// duas listas nunca se encontravam. O veredito então dizia que não havia
  /// perda justamente quando a perda era total. A ordem por nome é o fallback
  /// honesto, e o que ela não conseguir casar fica de fora em vez de virar
  /// paridade falsa.
  List<_ToolPair> _pairTools() {
    final live = _toolList(_live);
    final history = _toolList(_history);
    if (live.isEmpty || history.isEmpty) return const [];

    final pares = <_ToolPair>[];
    final usados = <int>{};
    for (final atual in live) {
      var alvo = -1;
      final id = atual.id;
      if (id != null && id.isNotEmpty) {
        alvo = history.indexWhere(
          (other) => other.id == id && !usados.contains(history.indexOf(other)),
        );
      }
      if (alvo < 0) {
        for (var index = 0; index < history.length; index++) {
          if (usados.contains(index)) continue;
          if (history[index].name == atual.name) {
            alvo = index;
            break;
          }
        }
      }
      if (alvo < 0) continue;
      usados.add(alvo);
      pares.add(_ToolPair(live: atual, history: history[alvo]));
    }
    return pares;
  }

  static String _ms(Duration value) =>
      '+${(value.inMilliseconds / 1000).toStringAsFixed(2)}s';
}

class _ToolShape {
  const _ToolShape({required this.name, this.id, this.detail, this.output});

  final String? id;
  final String name;
  final String? detail;
  final String? output;
}

class _ToolPair {
  const _ToolPair({required this.live, required this.history});

  final _ToolShape live;
  final _ToolShape history;
}
