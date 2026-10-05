import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/domain/models/hermes_toolset.dart';

void main() {
  test('HermesSkill lê os metadados anunciados pelo gateway', () {
    final skill = HermesSkill.fromJson({
      'name': 'hermes-agent',
      'description': 'Guia do agente',
      'category': 'autonomous-ai-agents',
    });

    expect(skill.name, 'hermes-agent');
    expect(skill.description, 'Guia do agente');
    expect(skill.category, 'autonomous-ai-agents');
  });

  test('HermesToolset preserva controles e ferramentas efetivos', () {
    final toolset = HermesToolset.fromJson({
      'name': 'terminal',
      'label': 'Terminal',
      'description': 'Comandos no host',
      'enabled': true,
      'configured': true,
      'tools': ['terminal', 'process'],
    });

    expect(toolset.enabled, isTrue);
    expect(toolset.configured, isTrue);
    expect(toolset.tools, ['terminal', 'process']);
  });
}
