import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/hermes_provider.dart';
import 'package:hermes_mobile/domain/models/model_options.dart';

/// A21.4: o payload de `/api/model/options` traz mais do que o app lia.
/// Campos medidos em `hermes_cli/inventory.py` (`_apply_pricing`,
/// `_apply_capabilities`, `_apply_picker_hints`).
void main() {
  test('opções preservam o provider e modelo efetivos do perfil', () {
    final options = ModelOptions.fromJson(const {
      'provider': 'openai-codex',
      'model': 'gpt-5.6-terra',
      'providers': <Object>[],
    });

    expect(options.effective?.provider, 'openai-codex');
    expect(options.effective?.model, 'gpt-5.6-terra');
  });

  test('lê preço, capacidades e o que a conta não pode escolher', () {
    final provider = HermesProvider.fromJson({
      'slug': 'nous',
      'name': 'Nous Portal',
      'models': ['hermes-4-70b', 'hermes-4-405b'],
      'total_models': 2,
      'authenticated': true,
      'free_tier': true,
      'unavailable_models': ['hermes-4-405b'],
      'pricing': {
        'hermes-4-70b': {'input': r'$0.00', 'output': r'$0.00', 'free': true},
        'hermes-4-405b': {
          'input': r'$3.00',
          'output': r'$15.00',
          'cache': r'$0.30',
        },
      },
      'capabilities': {
        'hermes-4-70b': {'fast': true, 'reasoning': false},
        'hermes-4-405b': {'fast': false, 'reasoning': true},
      },
    });

    expect(provider.freeTier, isTrue);
    expect(provider.isUnavailable('hermes-4-405b'), isTrue);
    expect(provider.isUnavailable('hermes-4-70b'), isFalse);
    expect(provider.pricing['hermes-4-70b']!.label, 'grátis');
    expect(provider.pricing['hermes-4-405b']!.label, r'in $3.00 · out $15.00');
    expect(provider.capabilities['hermes-4-70b']!.fast, isTrue);
    expect(provider.capabilities['hermes-4-70b']!.reasoning, isFalse);
  });

  test('sem catálogo de capacidades, raciocínio é assumido como aceito', () {
    // O servidor faz o mesmo: prefere oferecer o controle a escondê-lo de um
    // modelo capaz mas não catalogado. Divergir aqui daria duas respostas para
    // a mesma pergunta.
    final caps = ModelCapabilities.fromJson(const {});
    expect(caps.reasoning, isTrue);
    expect(caps.fast, isFalse);
  });

  test('provider não autenticado diz o que falta, com a frase do servidor', () {
    final provider = HermesProvider.fromJson(const {
      'slug': 'anthropic',
      'name': 'Anthropic',
      'models': <String>[],
      'authenticated': false,
      'auth_type': 'api_key',
      'key_env': 'ANTHROPIC_API_KEY',
      'warning': 'paste ANTHROPIC_API_KEY to activate',
    });

    expect(provider.setupHint, 'paste ANTHROPIC_API_KEY to activate');
  });

  test('sem frase do servidor, ainda diz qual chave falta', () {
    final provider = HermesProvider.fromJson(const {
      'slug': 'x',
      'authenticated': false,
      'key_env': 'X_API_KEY',
    });

    expect(provider.setupHint, contains('X_API_KEY'));
  });

  test('provider conectado não tem o que pedir', () {
    final provider = HermesProvider.fromJson(const {
      'slug': 'x',
      'authenticated': true,
      'warning': 'sobra do payload',
    });

    expect(provider.setupHint, isNull);
  });

  test(
    'mapa com forma inesperada vira ausência de informação, não exceção',
    () {
      final provider = HermesProvider.fromJson(const {
        'slug': 'x',
        'pricing': 'não é mapa',
        'capabilities': {'m': 'nem isto'},
        'unavailable_models': 'nem isto',
      });

      expect(provider.pricing, isEmpty);
      expect(provider.capabilities, isEmpty);
      expect(provider.unavailableModels, isEmpty);
    },
  );
}
