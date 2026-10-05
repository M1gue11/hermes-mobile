import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/tool_card_view.dart';

List<ToolCall> muitas(int quantas, {ToolStatus status = ToolStatus.done}) => [
      for (var i = 0; i < quantas; i++)
        ToolCall(name: 'read_file', arg: 'arquivo$i.md', status: status),
    ];

void main() {
  test('card curto não colapsa', () {
    final view = toolCardView(muitas(4));
    expect(view.visible, hasLength(4));
    expect(view.collapsed, isFalse);
  });

  test('esconder uma linha só não vale um controle a mais', () {
    final view = toolCardView(muitas(toolCardCollapseLimit + 1));
    expect(view.collapsed, isFalse);
    expect(view.visible, hasLength(toolCardCollapseLimit + 1));
  });

  test('card longo mostra o limite e conta o resto', () {
    final view = toolCardView(muitas(22));
    expect(view.visible, hasLength(toolCardCollapseLimit));
    expect(view.hidden, 22 - toolCardCollapseLimit);
    expect(view.collapsed, isTrue);
  });

  test('aberto mostra tudo', () {
    final view = toolCardView(muitas(22), expanded: true);
    expect(view.visible, hasLength(22));
    expect(view.hidden, 0);
  });

  test('linha que falhou nunca fica escondida', () {
    final tools = [
      ...muitas(20),
      const ToolCall(name: 'terminal', arg: 'rm -rf /tmp/x', status: ToolStatus.error),
    ];

    final view = toolCardView(tools);
    expect(view.visible.last.status, ToolStatus.error);
    expect(view.visible, hasLength(toolCardCollapseLimit + 1));
    expect(view.hidden, tools.length - view.visible.length);
  });

  test('linha em execução nunca fica escondida', () {
    final tools = [
      ...muitas(20),
      const ToolCall(name: 'terminal', arg: 'sleep 30', status: ToolStatus.running),
    ];

    final view = toolCardView(tools);
    expect(view.visible.last.status, ToolStatus.running);
  });

  test('a ordem original é preservada mesmo com linha obrigatória no fim', () {
    final tools = [
      ...muitas(10),
      const ToolCall(name: 'terminal', arg: 'falhou', status: ToolStatus.error),
      ...muitas(3),
    ];

    final view = toolCardView(tools);
    final nomes = view.visible.map((tool) => tool.arg).toList();
    expect(nomes.indexOf('arquivo0.md') < nomes.indexOf('falhou'), isTrue);
  });
}
