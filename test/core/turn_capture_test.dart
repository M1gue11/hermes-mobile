import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/diagnostics/turn_capture.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';

/// A captura existe para fechar o diagnóstico de A58/A59 sem virar um vazamento
/// de conteúdo. Estes testes protegem as duas metades: o relatório não pode
/// carregar valor de texto nem credencial, e o veredito precisa apontar a
/// camada certa quando as duas projeções divergem.
void main() {
  late TurnCapture capture;

  setUp(() {
    capture = TurnCapture()
      ..arm(true)
      ..beginTurn(sessionId: 'sess-abcdef123456', origin: 'teste');
  });

  group('redação', () {
    test('campo de texto sai como tamanho, nunca como conteúdo', () {
      capture.rawFrame('tool.complete', {
        'name': 'read_file',
        'tool_id': 'call_a1',
        'summary': 'o conteúdo secreto do arquivo do usuário',
      });

      final report = capture.report();
      expect(report, contains('tool.complete'));
      expect(report, contains('summary=40ch'));
      expect(report, isNot(contains('conteúdo secreto')));
    });

    test('chave com cara de credencial some mesmo com amostra ligada', () {
      capture
        ..setSampleText(true)
        ..rawFrame('session.info', {
          'ticket': 'tk_live_naopodevazar',
          'cookie': 'session=naopodevazar',
          'authorization': 'Bearer naopodevazar',
          'password': 'naopodevazar',
        });

      final report = capture.report();
      expect(report, isNot(contains('naopodevazar')));
      expect('<redigido>'.allMatches(report).length, 4);
    });

    test('amostra ligada mostra trecho curto de campo comum', () {
      capture
        ..setSampleText(true)
        ..rawFrame('message.delta', {'text': 'resposta parcial do agente'});

      expect(capture.report(), contains('«resposta parcial do agente»'));
    });

    test('identificador aparece encurtado', () {
      capture.rawFrame('tool.start', {
        'name': 'grep',
        'tool_id': 'call_0123456789abcdef',
      });

      final report = capture.report();
      expect(report, contains('tool_id=…89abcdef'));
      expect(report, isNot(contains('call_0123456789abcdef')));
    });

    test('parâmetro de saída não carrega o anexo em base64', () {
      capture.outgoing('file.attach', {
        'session_id': 'sess-abcdef123456',
        'content_base64': 'A' * 4096,
      });

      final report = capture.report();
      expect(report, contains('content_base64=4096ch'));
      expect(report, isNot(contains('AAAA')));
    });
  });

  group('veredito', () {
    /// Procura pelo prefixo, e não pelo índice: o veredito ganha linha nova
    /// conforme o contrato revela mais casos, e um teste preso na posição
    /// quebraria sem que nada de real tivesse mudado.
    String linha(TurnCapture alvo, String prefixo) => alvo.verdict().firstWhere(
      (line) => line.startsWith(prefixo),
      orElse: () => 'sem linha $prefixo em ${alvo.verdict()}',
    );

    ToolCall tool({
      String id = 'call_a1',
      String name = 'read_file',
      String? detail,
      String? output,
    }) => ToolCall(
      id: id,
      name: name,
      detail: detail,
      output: output,
      status: ToolStatus.done,
    );

    test('Q1 acusa output que só existe no histórico', () {
      capture
        ..liveProjection([
          TurnActivity.tool(
            id: 'v1',
            tool: tool(output: 'resumo curto'),
          ),
        ])
        ..historyProjection([
          TurnActivity.tool(
            id: 'h1',
            tool: tool(output: 'x' * 4000),
          ),
        ]);

      expect(
        linha(capture, 'Q1'),
        allOf(contains('Q1'), contains('NÃO'), contains('read_file')),
      );
    });

    test('Q1 confirma paridade quando o vivo já traz o mesmo output', () {
      capture
        ..liveProjection([
          TurnActivity.tool(
            id: 'v1',
            tool: tool(output: 'x' * 4000),
          ),
        ])
        ..historyProjection([
          TurnActivity.tool(
            id: 'h1',
            tool: tool(output: 'x' * 4000),
          ),
        ]);

      expect(linha(capture, 'Q1'), allOf(contains('Q1'), contains('SIM')));
    });

    test('Q2 separa reasoning.delta de reasoning.available', () {
      capture
        ..rawFrame('reasoning.available', {'text': 'lendo arquivos'})
        ..rawFrame('reasoning.available', {'text': 'comparando'});

      expect(
        linha(capture, 'Q2'),
        allOf(
          contains('Q2'),
          contains('NÃO'),
          contains('reasoning.available=2'),
        ),
      );
    });

    test('Q2 confirma quando o delta nativo chega e vira RunEvent', () {
      capture
        ..rawFrame('reasoning.delta', {'text': 'passo um'})
        ..adapterEvent(const RunEvent.reasoningDelta('passo um'));

      expect(
        linha(capture, 'Q2'),
        allOf(contains('Q2'), contains('SIM'), contains('1 frames')),
      );
    });

    // Medido no 0.20.1: o gateway não emite `tool.progress`. Se ele aparecer
    // numa captura, é contrato novo e precisa de decisão, não de tratamento
    // silencioso.
    test('Q3b avisa que tool.progress não deveria existir', () {
      capture
        ..rawFrame('tool.progress', {'tool_id': 'call_a1', 'text': 'lendo'})
        ..rawFrame('tool.progress', {'text': 'sem id'});

      expect(
        linha(capture, 'Q3b'),
        allOf(
          contains('PARCIAL'),
          contains('1/2'),
          contains('não emite este evento'),
        ),
      );
    });

    test('Q3 denuncia paralelismo do mesmo nome sem id para correlacionar', () {
      // Forma medida na Runs API: `tool.started` traz `tool` e `preview`, e
      // nenhum identificador. Quatro buscas simultâneas só podem ser casadas
      // por FIFO de nome, que é arbitrário quando elas terminam fora de ordem.
      for (var index = 0; index < 4; index++) {
        capture.rawSse('tool.started', '{"tool":"web_search","preview":"q"}');
      }
      capture.rawSse('tool.completed', '{"tool":"web_search","duration":1.5}');

      expect(
        linha(capture, 'Q3'),
        allOf(
          contains('NÃO'),
          contains('0/4 com id'),
          contains('web_search x4'),
        ),
      );
    });

    test('cabeçalho acusa quando o TUI abre e o turno corre pela Runs', () {
      capture
        ..rawFrame('gateway.ready', const {'change_events': true})
        ..rawSse('message.delta', '{"delta":"oi"}');

      expect(capture.report(), contains('FALLBACK'));
    });

    test('fallback nomeia o RPC que recusou', () {
      capture
        ..rawFrame('gateway.ready', const {})
        ..outgoing('session.resume', {'session_id': 'sess-1'})
        ..rpcError('session.resume', -32000, 'handler error')
        ..rawSse('message.delta', '{"delta":"oi"}');

      final report = capture.report();
      expect(report, contains('recusa em session.resume(-32000)'));
      expect(report, contains('ERRO session.resume'));
      expect(report, isNot(contains('handler error')));
    });

    test('resultado de RPC entra pela forma, não pelo conteúdo', () {
      capture
        ..outgoing('session.history', {'session_id': 'sess-1'})
        ..rpcResult('session.history', {
          'messages': [1, 2, 3],
          'title': 'conversa do usuário',
        });

      final report = capture.report();
      expect(report, contains('ok session.history'));
      expect(report, contains('messages=[3]'));
      expect(report, isNot(contains('conversa do usuário')));
    });

    test('Q4 flagra o summary do complete apagando os argumentos do start', () {
      capture
        ..rawFrame('tool.start', {
          'name': 'read_file',
          'tool_id': 'call_a1',
          'args_text': 'a' * 142,
        })
        ..liveProjection([
          TurnActivity.tool(
            id: 'v1',
            tool: tool(detail: 'b' * 210),
          ),
        ]);

      expect(
        linha(capture, 'Q4'),
        allOf(contains('Q4'), contains('NÃO'), contains('142ch->210ch')),
      );
    });

    test('Q1 casa por nome quando só o histórico tem id', () {
      // Forma medida na Runs API em 2026-08-15: ao vivo a tool não tem id, no
      // histórico tem. Casar só por id fazia o comparador desistir calado e
      // reportar paridade justamente onde a perda era total.
      capture
        ..liveProjection([
          TurnActivity.tool(
            id: 'v1',
            tool: const ToolCall(name: 'terminal', status: ToolStatus.done),
          ),
        ])
        ..historyProjection([
          TurnActivity.tool(
            id: 'h1',
            tool: const ToolCall(
              id: 'call_yUqsrQ9g',
              name: 'terminal',
              output: '{"output": "2026-08-15", "exit_code": 0}',
              status: ToolStatus.done,
            ),
          ),
        ]);

      expect(
        linha(capture, 'Q1'),
        allOf(contains('NÃO'), contains('terminal'), contains('0ch<')),
      );
    });

    test('Q6 acusa a prévia que repete a resposta final inteira', () {
      const resposta = 'Pessoa, ferramentas acionadas com sucesso.';
      capture
        ..adapterEvent(const RunEvent.activityPreview(resposta))
        ..adapterEvent(const RunEvent.completed(output: resposta));

      expect(
        linha(capture, 'Q6'),
        allOf(contains('SIM'), contains('duas vezes')),
      );
    });

    test('Q6 pega a prévia truncada, não só a idêntica', () {
      // Medido no TUI em 2026-08-15: reasoning.available veio com 501ch e o
      // message.complete com 716ch, o mesmo texto cortado. Comparar por
      // igualdade deixava a duplicação passar.
      const inicio =
          '**Teste concluído, Pessoa** Usei quatro ferramentas nesta conversa '
          'e todas responderam como esperado';
      capture
        ..adapterEvent(const RunEvent.activityPreview(inicio))
        ..adapterEvent(
          const RunEvent.completed(output: '$inicio, sem nenhuma falha.'),
        );

      expect(linha(capture, 'Q6'), contains('SIM'));
    });

    test('Q3 não alerta paralelismo quando toda abertura tem id', () {
      capture
        ..rawFrame('tool.start', {'tool_id': 'a', 'name': 'skill_view'})
        ..rawFrame('tool.start', {'tool_id': 'b', 'name': 'skill_view'});

      expect(
        linha(capture, 'Q3'),
        allOf(contains('SIM'), contains('2/2'), isNot(contains('FIFO'))),
      );
    });

    test('Q6 fica quieto quando a prévia é mesmo uma prévia', () {
      capture
        ..adapterEvent(const RunEvent.activityPreview('lendo arquivos'))
        ..adapterEvent(const RunEvent.completed(output: 'resposta final'));

      expect(linha(capture, 'Q6'), contains('NÃO'));
    });

    test('Q7 acusa raciocínio que só existe no histórico', () {
      capture
        ..liveProjection([
          const TurnActivity.activity(id: 'v1', text: 'preview'),
        ])
        ..historyProjection([
          const TurnActivity.reasoning(id: 'h1', text: 'Planning tool use'),
        ]);

      expect(linha(capture, 'Q7'), allOf(contains('SIM'), contains('1 bloco')));
    });

    test('Q5 compara a forma das duas projeções', () {
      capture
        ..liveProjection([
          const TurnActivity.activity(id: 'v1', text: 'preview'),
          TurnActivity.tool(id: 'v2', tool: tool()),
        ])
        ..historyProjection([
          const TurnActivity.reasoning(id: 'h1', text: 'raciocínio inteiro'),
          TurnActivity.tool(id: 'h2', tool: tool()),
        ]);

      expect(
        linha(capture, 'Q5'),
        allOf(
          contains('tools 1x1'),
          contains('raciocínio 0x1'),
          contains('atividade 1x0'),
        ),
      );
    });
  });

  group('sonda do gateway', () {
    test('leitura ok e resume recusado aponta o resume, não o banco', () {
      capture.setProbe([
        'ok gateway.ready  socket aberto e handshake concluído',
        'ok session.list  campos {sessions}',
        'ok session.history  campos {messages}',
        'ERRO session.resume  code=-32000 handler error',
      ]);

      expect(capture.report(), contains('só session.resume recusa'));
    });

    test('leitura e resume recusando juntos aponta o banco', () {
      capture.setProbe([
        'ok gateway.ready  socket aberto e handshake concluído',
        'ERRO session.list  code=-32000 handler error',
        'ERRO session.history  code=-32000 handler error',
        'ERRO session.resume  code=-32000 handler error',
      ]);

      expect(capture.report(), contains('a conexão do banco morreu'));
    });

    test('sonda sobrevive ao início de um turno novo', () {
      capture
        ..setProbe(['ok session.list  campos {sessions}'])
        ..arm(true)
        ..beginTurn(sessionId: 'sess-nova', origin: 'envio')
        ..rawFrame('gateway.ready', const {});

      expect(capture.report(), contains('SONDA DO GATEWAY'));
    });

    test('sonda sozinha já produz relatório legível', () {
      final sozinha = TurnCapture()
        ..setProbe(['ERRO session.resume  code=-32000 handler error']);

      expect(sozinha.report(), contains('ERRO session.resume'));
    });
  });

  group('ciclo de vida', () {
    test('sem armar, nenhum frame é observado', () {
      final ocioso = TurnCapture()
        ..beginTurn(sessionId: 'sess-1', origin: 'teste')
        ..rawFrame('tool.start', {'name': 'read_file'});

      expect(ocioso.hasCapture, isFalse);
      expect(ocioso.capturing, isFalse);
    });

    test('armar vale por um turno só', () {
      capture.endTurn('turno concluído');
      capture.beginTurn(sessionId: 'sess-2', origin: 'segundo');
      capture.rawFrame('tool.start', {'name': 'nao_deve_entrar'});

      expect(capture.capturing, isFalse);
      expect(capture.report(), isNot(contains('nao_deve_entrar')));
    });

    test('turno encerrado registra o desfecho no cabeçalho', () {
      capture
        ..rawFrame('message.start', const {})
        ..endTurn('turno falhou');

      expect(capture.report(), contains('estado=turno falhou'));
    });

    // A67: a queda de transporte era muda. Ela precisa aparecer mesmo quando
    // ninguém armou a captura, porque é justamente aí que ela passava batida.
    test('queda de transporte é registrada sem captura armada', () {
      final ocioso = TurnCapture();
      expect(ocioso.lastFallbackReason, isNull);

      ocioso.transportFallback('openLiveTurn recusou (TimeoutException)');
      expect(
        ocioso.lastFallbackReason,
        'openLiveTurn recusou (TimeoutException)',
      );
      expect(ocioso.hasCapture, isFalse);

      // E some quando o TUI volta a segurar o turno.
      ocioso.transportHeld();
      expect(ocioso.lastFallbackReason, isNull);
    });

    test('com captura armada, a queda também entra no relatório', () {
      capture.transportFallback('nenhuma sessão pareada do Dashboard');

      expect(capture.report(), contains('nenhuma sessão pareada'));
    });

    test('limpar apaga a captura inteira', () {
      capture
        ..rawFrame('message.start', const {})
        ..clear();

      expect(capture.hasCapture, isFalse);
      expect(capture.report(), contains('Nenhuma captura'));
    });
  });
}
