import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';

SubagentEvent _event(String type, Map<String, dynamic> payload) =>
    SubagentEvent.fromGateway(type, {
      'goal': 'Ler os logs',
      'task_count': 2,
      'task_index': 0,
      ...payload,
    })!;

List<TurnActivity> _apply(List<SubagentEvent> events) {
  var items = <TurnActivity>[];
  for (var i = 0; i < events.length; i++) {
    items = applySubagentEvent(items, events[i], blockId: 'b$i');
  }
  return items;
}

void main() {
  test('normaliza o frame do 0.22.6 e ignora tipo desconhecido', () {
    final event = _event('subagent.complete', {
      'subagent_id': 'sa-1',
      'status': 'timeout',
      'summary': '  3 erros encontrados  ',
      'duration_seconds': 12.5,
    });
    expect(event.kind, SubagentEventKind.complete);
    expect(event.key, 'sa-1');
    expect(event.phase, SubagentPhase.failed);
    expect(event.summary, '3 erros encontrados');
    expect(event.duration, const Duration(milliseconds: 12500));
    expect(SubagentEvent.fromGateway('subagent.text', const {}), isNull);

    final legacy = _event('subagent.start', {'delegation_id': 'd9'});
    expect(legacy.key, 'd9#0');
    expect(_event('subagent.start', const {}).key, 'delegate#0');
  });

  test('um agente vira um bloco só, do início ao resumo', () {
    final items = _apply([
      _event('subagent.spawn_requested', {'subagent_id': 'sa-1'}),
      _event('subagent.start', {'subagent_id': 'sa-1'}),
      _event('subagent.tool', {
        'subagent_id': 'sa-1',
        'tool_name': 'terminal',
        'tool_preview': 'tail -n 50 app.log',
      }),
      _event('subagent.thinking', {'subagent_id': 'sa-1', 'text': 'Achei.'}),
      _event('subagent.complete', {
        'subagent_id': 'sa-1',
        'status': 'completed',
        'summary': 'Nenhum erro.',
      }),
    ]);

    final run = (items.single as TurnSubagentActivity).run;
    expect((items.single as TurnSubagentActivity).id, 'b0');
    expect(run.phase, SubagentPhase.completed);
    expect(run.toolCalls, 1);
    expect(run.summary, 'Nenhum erro.');
    expect(run.goal, 'Ler os logs');
  });

  test('agentes em paralelo ficam separados pela chave', () {
    final items = _apply([
      _event('subagent.start', {'subagent_id': 'a', 'task_index': 0}),
      _event('subagent.start', {'subagent_id': 'b', 'task_index': 1}),
      _event('subagent.tool', {'subagent_id': 'b', 'tool_name': 'grep'}),
      _event('subagent.complete', {'subagent_id': 'a', 'status': 'failed'}),
    ]);

    final runs = items.cast<TurnSubagentActivity>().map((i) => i.run).toList();
    expect(runs.map((r) => r.key), ['a', 'b']);
    expect(runs[0].phase, SubagentPhase.failed);
    expect(runs[1].phase, SubagentPhase.running);
    expect(runs[1].lastNote, 'grep');
  });

  test('emissor sem id: nova delegação com o mesmo índice abre bloco novo', () {
    final items = _apply([
      _event('subagent.start', const {}),
      _event('subagent.complete', {'status': 'completed'}),
      _event('subagent.start', {'goal': 'Outra tarefa'}),
    ]);

    expect(items, hasLength(2));
    expect((items.last as TurnSubagentActivity).run.goal, 'Outra tarefa');
  });

  test('fim do turno fecha quem ficou aberto, conforme o desfecho', () {
    final open = _apply([
      _event('subagent.start', {'subagent_id': 'a'}),
    ]);
    SubagentPhase phase(List<TurnActivity> items) =>
        (items.single as TurnSubagentActivity).run.phase;

    expect(phase(settleTurnTools(open)), SubagentPhase.completed);
    expect(
      phase(settleTurnTools(open, failed: true)),
      SubagentPhase.interrupted,
    );
  });
}
