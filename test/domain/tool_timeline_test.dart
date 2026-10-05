import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/tool_timeline.dart';

/// Eventos montados com a forma que a Runs API `0.19.0` manda de verdade,
/// medida em `gateway/platforms/api_server.py`, `_make_run_event_callback`:
///
/// ```
/// tool.started    {event, run_id, timestamp, tool, preview}
/// tool.completed  {event, run_id, timestamp, tool, duration, error}
/// ```
///
/// Ou seja: **sem identificador de chamada** nos dois, e **sem preview** no
/// segundo. É essa combinação que produzia as linhas fantasmas do A14.
ToolCall iniciou(String name, String arg) => ToolCall(name: name, arg: arg);

ToolCall terminou(String name, String duration, {bool erro = false}) =>
    ToolCall(
      name: name,
      duration: duration,
      status: erro ? ToolStatus.error : ToolStatus.done,
    );

List<ToolCall> aplicar(List<ToolCall> eventos) {
  var timeline = <ToolCall>[];
  for (final evento in eventos) {
    timeline = applyToolEvent(timeline, evento);
  }
  return timeline;
}

void main() {
  group('applyToolEvent', () {
    test('par simples fecha a mesma linha e preserva o argumento', () {
      final timeline = aplicar([
        const ToolCall(
          name: 'read_file',
          arg: 'lib/main.dart',
          detail: 'entrada completa',
          output: 'saída parcial',
        ),
        terminou('read_file', '0.041'),
      ]);

      expect(timeline, hasLength(1));
      expect(timeline.single.name, 'read_file');
      expect(timeline.single.arg, 'lib/main.dart');
      expect(timeline.single.detail, 'entrada completa');
      expect(timeline.single.output, 'saída parcial');
      expect(timeline.single.duration, '0.041');
      expect(timeline.single.status, ToolStatus.done);
    });

    test('regressão A14: três chamadas do mesmo nome em paralelo', () {
      // A captura do celular mostrou três `skill_view` seguidos, dois deles sem
      // argumento nenhum. A regra antiga casava o `tool.started` seguinte com a
      // linha ainda aberta do anterior, então três aberturas colapsavam em uma
      // e os dois fechamentos restantes viravam linha nova e vazia.
      final timeline = aplicar([
        iniciou('skill_view', 'brazil-price-research'),
        iniciou('skill_view', 'consorcio-ancora'),
        iniciou('skill_view', 'telegram-digest'),
        terminou('skill_view', '0.162'),
        terminou('skill_view', '0.155'),
        terminou('skill_view', '0.144'),
      ]);

      expect(
        timeline,
        hasLength(3),
        reason: 'uma linha por chamada, nem mais nem menos',
      );
      expect(
        timeline.map((tool) => tool.arg),
        ['brazil-price-research', 'consorcio-ancora', 'telegram-digest'],
        reason: 'nenhuma linha pode perder o argumento que veio na abertura',
      );
      expect(timeline.every((tool) => tool.status == ToolStatus.done), isTrue);
      // FIFO: a primeira aberta recebe a primeira duração que chega.
      expect(timeline.map((tool) => tool.duration), [
        '0.162',
        '0.155',
        '0.144',
      ]);
    });

    test('abertura nunca reaproveita linha aberta do mesmo nome', () {
      final timeline = aplicar([
        iniciou('terminal', 'git status'),
        iniciou('terminal', 'git diff'),
      ]);

      expect(timeline, hasLength(2));
      expect(timeline.map((tool) => tool.arg), ['git status', 'git diff']);
      expect(
        timeline.every((tool) => tool.status == ToolStatus.running),
        isTrue,
      );
    });

    test('fechamento não vaza para uma linha já fechada', () {
      final timeline = aplicar([
        iniciou('search_files', 'padrao'),
        terminou('search_files', '0.010'),
        terminou('search_files', '0.020'),
      ]);

      expect(
        timeline,
        hasLength(2),
        reason: 'o segundo fechamento é órfão de verdade',
      );
      expect(timeline.first.arg, 'padrao');
      expect(timeline.first.duration, '0.010');
      expect(timeline.last.arg, isEmpty);
      expect(timeline.last.duration, '0.020');
    });

    test('erro no fechamento marca a linha certa', () {
      final timeline = aplicar([
        iniciou('read_file', 'nao/existe.dart'),
        terminou('read_file', '0.003', erro: true),
      ]);

      expect(timeline.single.status, ToolStatus.error);
      expect(timeline.single.arg, 'nao/existe.dart');
    });

    test(
      'identificador, quando existir, tem precedência sobre nome e ordem',
      () {
        // Caminho do gateway TUI (trilha B), onde a chamada tem id de verdade:
        // aí o fechamento acha o par exato mesmo fora de ordem.
        var timeline = <ToolCall>[];
        timeline = applyToolEvent(
          timeline,
          const ToolCall(id: 'call_a', name: 'skill_view', arg: 'primeira'),
        );
        timeline = applyToolEvent(
          timeline,
          const ToolCall(id: 'call_b', name: 'skill_view', arg: 'segunda'),
        );
        timeline = applyToolEvent(
          timeline,
          const ToolCall(
            id: 'call_b',
            name: 'skill_view',
            duration: '0.5',
            status: ToolStatus.done,
          ),
        );

        expect(timeline, hasLength(2));
        expect(timeline.first.status, ToolStatus.running);
        expect(timeline.last.status, ToolStatus.done);
        expect(timeline.last.arg, 'segunda');
        expect(timeline.last.duration, '0.5');
      },
    );

    test('linha com id não é fechada por evento sem id', () {
      // Misturar os dois transportes não pode fazer um evento anônimo roubar o
      // par de uma chamada correlacionada.
      var timeline = <ToolCall>[
        const ToolCall(id: 'call_a', name: 'terminal', arg: 'ls'),
      ];
      timeline = applyToolEvent(timeline, terminou('terminal', '0.9'));

      expect(timeline, hasLength(2));
      expect(timeline.first.status, ToolStatus.running);
      expect(timeline.first.id, 'call_a');
    });
  });

  group('settleTools', () {
    test('fecha o que ficou aberto e não toca no resto', () {
      final settled = settleTools([
        const ToolCall(
          name: 'a',
          arg: 'x',
          status: ToolStatus.done,
          duration: '1.0',
        ),
        const ToolCall(name: 'b', arg: 'y'),
        const ToolCall(name: 'c', arg: 'z', status: ToolStatus.error),
      ]);

      expect(settled.map((tool) => tool.status), [
        ToolStatus.done,
        ToolStatus.done,
        ToolStatus.error,
      ]);
      expect(settled[0].duration, '1.0');
      expect(settled[1].arg, 'y');
    });

    test('run que falhou marca as pendências como erro', () {
      final settled = settleTools([
        const ToolCall(name: 'b', arg: 'y'),
      ], failed: true);
      expect(settled.single.status, ToolStatus.error);
    });
  });
}
