import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/hermes_model.dart';
import 'package:hermes_mobile/domain/models/model_lock.dart';
import 'package:hermes_mobile/domain/models/model_options.dart';
import 'package:hermes_mobile/domain/models/model_selection.dart';

void main() {
  const options = ModelOptions(
    model: 'gpt-5.6-terra',
    provider: 'openai-codex',
  );

  test('conversa nova usa o par efetivo, não o alias anunciado', () {
    expect(
      resolveModelLock(
        options: options,
        advertised: const [HermesModel(id: 'hermes-agent')],
      ),
      const ModelLock(model: 'gpt-5.6-terra', provider: 'openai-codex'),
    );
  });

  test('sessão legada presa ao alias é recuperada para o par efetivo', () {
    expect(
      resolveModelLock(
        options: options,
        preferred: const ModelLock(model: 'hermes-agent'),
      ),
      const ModelLock(model: 'gpt-5.6-terra', provider: 'openai-codex'),
    );
  });

  test('escolha concreta da conversa não é trocada pelo padrão atual', () {
    expect(
      resolveModelLock(
        options: options,
        preferred: const ModelLock(model: 'gpt-5.5', provider: 'openai-codex'),
      ),
      const ModelLock(model: 'gpt-5.5', provider: 'openai-codex'),
    );
  });

  test('modelo efetivo enriquece provider ausente do mesmo modelo', () {
    expect(
      resolveModelLock(
        options: options,
        preferred: const ModelLock(model: 'gpt-5.6-terra'),
      ),
      const ModelLock(model: 'gpt-5.6-terra', provider: 'openai-codex'),
    );
  });

  test('catálogo contendo apenas alias não produz override inválido', () {
    expect(
      resolveModelLock(
        options: const ModelOptions(),
        advertised: const [HermesModel(id: 'hermes-agent')],
      ),
      isNull,
    );
  });

  test('modelo concreto de v1 models ainda serve como fallback', () {
    expect(
      resolveModelLock(
        options: const ModelOptions(),
        advertised: const [
          HermesModel(id: 'hermes-agent'),
          HermesModel(id: 'modelo-direto'),
        ],
      ),
      const ModelLock(model: 'modelo-direto'),
    );
  });

  group('shortModelLabel', () {
    test('encurta a família hermes-<geração>-<tamanho>', () {
      expect(shortModelLabel('hermes-4-70b'), 'H4 70B');
      expect(shortModelLabel('hermes-3-8b'), 'H3 8B');
    });

    test('id fora do padrão é mostrado como veio', () {
      // O bug: `hermes-agent` virava o ilegível `H AGENT`.
      expect(shortModelLabel('hermes-agent'), 'HERMES-AGENT');
      expect(shortModelLabel('gpt-5.6-terra'), 'GPT-5.6-TERRA');
    });

    test('sem modelo, identifica o agente genericamente', () {
      expect(shortModelLabel(null), 'HERMES');
      expect(shortModelLabel('  '), 'HERMES');
    });
  });
}
