import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/core/theme/design_scale.dart';
import 'package:hermes_mobile/core/theme/hermes_tokens.dart';
import 'package:hermes_mobile/data/config/app_settings_store.dart';
import 'package:hermes_mobile/features/settings/settings_provider.dart';
import 'package:hermes_mobile/features/settings/agent_persona.dart';

class _RecordingSettingsStore implements AppSettingsStore {
  final List<StoredAppSettings> writes = [];

  @override
  Future<StoredAppSettings?> read() async => null;

  @override
  Future<void> save(StoredAppSettings settings) async {
    writes.add(settings);
  }
}

Future<void> _until(bool Function() condition) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('Condição não atingida');
}

void main() {
  test('modo cronológico é o padrão quando não existe preferência', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(appSettingsProvider).chronologicalActivity, isTrue);
  });

  test('restaura preferências e usa fallback por campo desconhecido', () {
    final container = ProviderContainer(
      overrides: [
        appSettingsInitialProvider.overrideWithValue((
          agentGender: 'feminine',
          agentName: 'Cláudia',
          atmosphere: 'jornal',
          chronologicalActivity: true,
          spinner: 'nao-existe',
          textSize: 'maior',
          showActivity: false,
          instructions: 'Português.',
        )),
      ],
    );
    addTearDown(container.dispose);

    final settings = container.read(appSettingsProvider);
    expect(settings.agentGender, AgentGender.feminine);
    expect(settings.agentName, 'Cláudia');
    expect(settings.atmosphere, Atmosphere.jornal);
    expect(settings.chronologicalActivity, isTrue);
    expect(settings.spinner, 'helix');
    expect(settings.textSize, TextSize.maior);
    expect(settings.showActivity, isFalse);
    expect(settings.instructions, 'Português.');
  });

  test('cada alteração salva um snapshot completo em ordem', () async {
    final store = _RecordingSettingsStore();
    final container = ProviderContainer(
      overrides: [appSettingsStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    final settings = container.read(appSettingsProvider.notifier);

    settings.setAtmosphere(Atmosphere.tecnico);
    settings.setTextSize(TextSize.maximo);
    settings.setChronologicalActivity(true);
    settings.setShowActivity(false);
    settings.setInstructions('Seja breve.');
    settings.setAgentPersona(name: '  Cláudia  ', gender: AgentGender.feminine);

    await _until(() => store.writes.length == 6);
    final last = store.writes.last;
    expect(last.atmosphere, 'tecnico');
    expect(last.textSize, 'maximo');
    expect(last.chronologicalActivity, isTrue);
    expect(last.showActivity, isFalse);
    expect(last.instructions, 'Seja breve.');
    expect(last.agentName, 'Cláudia');
    expect(last.agentGender, 'feminine');
  });

  test('persona derivada usa fallback e flexões centralizadas', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(agentPersonaProvider).composerHint,
      'Fale com Hermes…',
    );

    container
        .read(appSettingsProvider.notifier)
        .setAgentPersona(name: 'Cláudia', gender: AgentGender.feminine);
    final feminine = container.read(agentPersonaProvider);
    expect(feminine.composerHint, 'Peça à Cláudia…');
    expect(feminine.questionLabel, 'CLÁUDIA PERGUNTA');
    expect(
      feminine.clarificationSemantics,
      'A Cláudia está te perguntando algo',
    );

    container
        .read(appSettingsProvider.notifier)
        .setAgentPersona(name: 'Caio', gender: AgentGender.masculine);
    expect(container.read(agentPersonaProvider).composerHint, 'Peça ao Caio…');
    expect(
      container.read(agentPersonaProvider).clarificationSemantics,
      'O Caio está te perguntando algo',
    );
  });
}
