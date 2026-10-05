import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/http/http_hermes_repository.dart';
import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';

void main() {
  group('parseSse (contrato estrito da Runs API)', () {
    test('fluxo real intercalado preserva delta, tool e conclusão', () {
      final events = [
        HttpHermesRepository.parseSse(null, '{"event":"message.delta","delta":"olá"}'),
        HttpHermesRepository.parseSse(null, '{"event":"tool.started","tool":"read_file","preview":"a.md"}'),
        HttpHermesRepository.parseSse(null, '{"event":"tool.completed","tool":"read_file","duration":0.2,"error":false}'),
        HttpHermesRepository.parseSse(null, '{"event":"run.completed","output":"olá"}'),
      ];
      expect(events.map((item) => item.runtimeType), [RunTextDelta, RunToolProgress, RunToolProgress, RunCompleted]);
      expect((events[2]! as RunToolProgress).tool.status, ToolStatus.done);
    });

    test('progresso de tool', () {
      final e = HttpHermesRepository.parseSse(
        'tool.started',
        '{"name":"read_file","arg":"x.md","status":"running"}',
      );
      expect(e, isA<RunToolProgress>());
      final tool = (e! as RunToolProgress).tool;
      expect(tool.name, 'read_file');
      expect(tool.arg, 'x.md');
      expect(tool.status, ToolStatus.running);
    });

    test('tool concluída via contrato', () {
      final e = HttpHermesRepository.parseSse(
        'tool.completed',
        '{"name":"terminal","status":"completed"}',
      );
      expect((e! as RunToolProgress).tool.status, ToolStatus.done);
    });

    test('tool.failed não faz parte do contrato e permanece desconhecido', () {
      final event = HttpHermesRepository.parseSse(
        'tool.failed',
        '{"name":"terminal","error":true}',
      );

      expect(event, isA<RunUnknown>());
      expect((event! as RunUnknown).type, 'tool.failed');
    });

    // Medido em 2026-08-15 num turno real: o texto deste evento vem idêntico
    // ao `output` do `run.completed`. Virava bloco de atividade e a resposta
    // inteira aparecia duas vezes na timeline ao vivo.
    test('reasoning.available não vira bloco: duplicava a resposta', () {
      final e = HttpHermesRepository.parseSse(
        'reasoning.available',
        '{"text":"a resposta inteira de novo"}',
      );
      expect(e, isA<RunUnknown>());
      expect((e! as RunUnknown).type, 'reasoning.available');
    });


    test('evento real message.delta da Runs API', () {
      final e = HttpHermesRepository.parseSse(
        null,
        '{"event":"message.delta","run_id":"run_1","delta":"olá"}',
      );
      expect((e! as RunTextDelta).text, 'olá');
    });

    test('evento real tool.completed marca a ferramenta como concluída', () {
      final e = HttpHermesRepository.parseSse(
        null,
        '{"event":"tool.completed","tool_name":"read_file","args":{"path":"a.md"}}',
      );
      final tool = e! as RunToolProgress;
      expect(tool.tool.status, ToolStatus.done);
      expect(tool.tool.name, 'read_file');
    });

    test('tool.completed real usa o campo tool e respeita erro do gateway', () {
      final ok = HttpHermesRepository.parseSse(
        null,
        '{"event":"tool.completed","tool":"terminal","error":false}',
      )! as RunToolProgress;
      final failed = HttpHermesRepository.parseSse(
        null,
        '{"event":"tool.completed","tool":"terminal","error":true}',
      )! as RunToolProgress;
      expect(ok.tool.status, ToolStatus.done);
      expect(failed.tool.status, ToolStatus.error);
    });

    test('evento real run.completed preserva o output', () {
      final e = HttpHermesRepository.parseSse(
        null,
        '{"event":"run.completed","output":"pronto"}',
      );
      expect((e! as RunCompleted).output, 'pronto');
    });

    test('evento real run.cancelled atualiza o status', () {
      final e = HttpHermesRepository.parseSse(null, '{"event":"run.cancelled"}');
      expect((e! as RunStatusEvent).status, RunStatus.cancelled);
    });

    test('[DONE] encerra', () {
      expect(HttpHermesRepository.parseSse(null, '[DONE]'), isA<RunCompleted>());
    });

    test('failed com mensagem', () {
      final e = HttpHermesRepository.parseSse('run.failed', '{"message":"boom"}');
      expect((e! as RunFailed).error, 'boom');
    });

    test('approval.request vira evento tipado, não desconhecido', () {
      // Antes do A18 este evento caía em `RunUnknown` e a run ficava parada sem
      // que a tela dissesse por quê.
      final event = HttpHermesRepository.parseSse(
        null,
        '{"event":"approval.request","run_id":"run_9","timestamp":1784217600.0,'
        '"command":"rm -rf /tmp/x","description":"Remoção recursiva",'
        '"pattern_key":"rm_recursive","allow_permanent":true,'
        '"choices":["once","session","always","deny"]}',
      );

      expect(event, isA<RunApprovalRequest>());
      final pedido = (event! as RunApprovalRequest).request;
      expect(pedido.runId, 'run_9');
      expect(pedido.command, 'rm -rf /tmp/x');
      expect(pedido.choices, hasLength(4));
    });

    test('approval.responded fecha a pendência', () {
      final event = HttpHermesRepository.parseSse(
        null,
        '{"event":"approval.responded","run_id":"run_9","choice":"deny","resolved":1}',
      );
      expect((event! as RunApprovalResolved).choice, ApprovalChoice.deny);
    });

    test('approval.responded com escolha ilegível não inventa decisão', () {
      final event = HttpHermesRepository.parseSse(
        null,
        '{"event":"approval.responded","run_id":"run_9","choice":"???"}',
      );
      expect(event, isA<RunUnknown>());
    });

    test('evento desconhecido preserva tipo e payload', () {
      final e = HttpHermesRepository.parseSse('weird.event', '{"foo":1}');
      expect(e, isA<RunUnknown>());
      expect((e! as RunUnknown).type, 'weird.event');
      expect((e as RunUnknown).data['foo'], 1);
    });

    test('frame vazio retorna null', () {
      expect(HttpHermesRepository.parseSse(null, ''), isNull);
    });
  });

  group('parseStatus', () {
    test('mapeia estados conhecidos', () {
      expect(HttpHermesRepository.parseStatus('running'), RunStatus.running);
      expect(HttpHermesRepository.parseStatus('in_progress'), RunStatus.inProgress);
      expect(HttpHermesRepository.parseStatus('cancelled'), RunStatus.cancelled);
      expect(HttpHermesRepository.parseStatus('canceled'), RunStatus.cancelled);
    });

    test('desconhecido vira unknown', () {
      expect(HttpHermesRepository.parseStatus('teleporting'), RunStatus.unknown);
    });
  });
}
