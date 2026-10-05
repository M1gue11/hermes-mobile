import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/turn_activity.dart';

void main() {
  test('conclusão atualiza a ferramenta na posição em que começou', () {
    var items = const <TurnActivity>[
      TurnActivity.activity(id: 'a1', text: 'Vou ler o arquivo.'),
    ];
    items = applyTurnToolEvent(
      items,
      const ToolCall(
        name: 'read_file',
        arg: 'plano.md',
        detail: 'entrada completa',
        output: 'saída parcial',
      ),
      blockId: 't1',
    );
    items = [
      ...items,
      const TurnActivity.activity(id: 'a2', text: 'Arquivo encontrado.'),
    ];
    items = applyTurnToolEvent(
      items,
      const ToolCall(
        name: 'read_file',
        duration: '0.2',
        status: ToolStatus.done,
      ),
      blockId: 'nao-usado',
    );

    expect(items[0], isA<TurnActivityPreview>());
    expect(items[1], isA<TurnToolActivity>());
    expect(items[2], isA<TurnActivityPreview>());
    final tool = (items[1] as TurnToolActivity).tool;
    expect(tool.arg, 'plano.md');
    expect(tool.detail, 'entrada completa');
    expect(tool.output, 'saída parcial');
    expect(tool.status, ToolStatus.done);
    expect(tool.duration, '0.2');
  });

  test('ferramentas homônimas sem id fecham em FIFO', () {
    var items = <TurnActivity>[];
    items = applyTurnToolEvent(
      items,
      const ToolCall(name: 'read_file', arg: 'primeiro.md'),
      blockId: 't1',
    );
    items = applyTurnToolEvent(
      items,
      const ToolCall(name: 'read_file', arg: 'segundo.md'),
      blockId: 't2',
    );
    items = applyTurnToolEvent(
      items,
      const ToolCall(name: 'read_file', status: ToolStatus.done),
      blockId: 'nao-usado',
    );

    final tools = toolsFromTurnActivity(items);
    expect(tools.map((tool) => tool.arg), ['primeiro.md', 'segundo.md']);
    expect(tools.map((tool) => tool.status), [
      ToolStatus.done,
      ToolStatus.running,
    ]);
  });

  test('encerramento da run resolve somente os blocos de ferramenta', () {
    const items = <TurnActivity>[
      TurnActivity.reasoning(id: 'r1', text: 'Plano'),
      TurnActivity.tool(
        id: 't1',
        tool: ToolCall(name: 'terminal'),
      ),
    ];

    final settled = settleTurnTools(items, failed: true);

    expect(settled.first, items.first);
    expect((settled.last as TurnToolActivity).tool.status, ToolStatus.error);
  });
}
