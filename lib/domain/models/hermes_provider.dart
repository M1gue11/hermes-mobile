/// Preço de um modelo, já formatado pelo servidor.
///
/// Medido em `hermes_cli/inventory.py`, `_apply_pricing`: o Hermes formata os
/// valores por milhão de tokens (`$3.00`) antes de mandar, "so the GUI just
/// renders strings". O app **não** recalcula nem converte moeda: exibir um
/// número diferente do que o servidor calculou seria pior que não exibir.
class ModelPricing {
  const ModelPricing({this.input, this.output, this.cache, this.free = false});

  final String? input;
  final String? output;
  final String? cache;
  final bool free;

  bool get isEmpty => input == null && output == null && cache == null && !free;

  factory ModelPricing.fromJson(Map<String, dynamic> json) => ModelPricing(
        input: json['input']?.toString(),
        output: json['output']?.toString(),
        cache: json['cache']?.toString(),
        free: json['free'] as bool? ?? false,
      );

  /// Linha curta para caber ao lado do nome do modelo.
  String get label {
    if (free) return 'grátis';
    final partes = [
      if (input != null) 'in $input',
      if (output != null) 'out $output',
    ];
    return partes.join(' · ');
  }
}

/// O que um modelo aceita, medido em `_apply_capabilities`.
///
/// `reasoning` vem do catálogo models.dev quando conhecido e **assume `true`**
/// quando não: o servidor prefere oferecer o controle a escondê-lo de um modelo
/// capaz mas não catalogado. O app repete essa escolha em vez de inventar outra.
class ModelCapabilities {
  const ModelCapabilities({this.fast = false, this.reasoning = true});

  final bool fast;
  final bool reasoning;

  factory ModelCapabilities.fromJson(Map<String, dynamic> json) => ModelCapabilities(
        fast: json['fast'] as bool? ?? false,
        reasoning: json['reasoning'] as bool? ?? true,
      );
}

/// Provider configurado e anunciado pelo Hermes Gateway.
///
/// O payload é estritamente informativo: não contém chaves, URLs privadas nem
/// permite alterar a configuração do servidor pelo aplicativo.
class HermesProvider {
  const HermesProvider({
    required this.id,
    required this.name,
    required this.models,
    required this.totalModels,
    this.isCurrent = false,
    this.authenticated = false,
    this.authType,
    this.keyEnv,
    this.warning,
    this.isUserDefined = false,
    this.pricing = const {},
    this.capabilities = const {},
    this.freeTier = false,
    this.unavailableModels = const [],
  });

  final String id;
  final String name;
  final List<String> models;
  final int totalModels;
  final bool isCurrent;
  final bool authenticated;
  final String? authType;

  /// Variável de ambiente que falta para o provider ficar utilizável.
  final String? keyEnv;

  /// O que o servidor diz que falta fazer, quando o provider não está pronto.
  final String? warning;

  final bool isUserDefined;

  /// Preço por modelo, quando o provider tem preço ao vivo.
  final Map<String, ModelPricing> pricing;

  /// O que cada modelo aceita.
  final Map<String, ModelCapabilities> capabilities;

  /// Conta em plano gratuito (só a Nous informa isto).
  final bool freeTier;

  /// Modelos que esta conta **não** pode escolher, por serem pagos num plano
  /// gratuito. Oferecer um botão que o backend recusaria é pior que não
  /// oferecer.
  final List<String> unavailableModels;

  bool isUnavailable(String model) => unavailableModels.contains(model);

  /// O que dizer quando o provider aparece mas não dá para usar.
  ///
  /// Prefere a frase do servidor, que sabe o motivo exato; só cai no texto
  /// genérico quando ela não vem.
  String? get setupHint {
    if (authenticated) return null;
    final doServidor = warning?.trim();
    if (doServidor != null && doServidor.isNotEmpty) return doServidor;
    final env = keyEnv?.trim();
    if (env != null && env.isNotEmpty) return 'falta a chave $env no servidor';
    return 'precisa ser configurado no servidor';
  }

  factory HermesProvider.fromJson(Map<String, dynamic> json) {
    final rawModels = json['models'];
    return HermesProvider(
      id: json['id']?.toString() ?? json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? json['label']?.toString() ?? json['slug']?.toString() ?? '',
      models: rawModels is List
          ? rawModels.map((value) => value.toString()).toList(growable: false)
          : const [],
      totalModels: (json['total_models'] as num?)?.toInt() ?? 0,
      isCurrent: json['is_current'] as bool? ?? false,
      authenticated: json['authenticated'] as bool? ?? false,
      authType: json['auth_type']?.toString(),
      keyEnv: json['key_env']?.toString(),
      warning: json['warning']?.toString(),
      isUserDefined: json['is_user_defined'] as bool? ?? false,
      pricing: _mapOf(json['pricing'], ModelPricing.fromJson),
      capabilities: _mapOf(json['capabilities'], ModelCapabilities.fromJson),
      freeTier: json['free_tier'] as bool? ?? false,
      unavailableModels: json['unavailable_models'] is List
          ? (json['unavailable_models'] as List)
              .map((value) => value.toString())
              .toList(growable: false)
          : const [],
    );
  }

  /// Lê um mapa por modelo sem confiar na forma: entrada estranha vira ausência
  /// de informação, não exceção na tela.
  static Map<String, T> _mapOf<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
    if (raw is! Map) return const {};
    final out = <String, T>{};
    raw.forEach((key, value) {
      if (value is Map) {
        out[key.toString()] = parse(value.map((k, v) => MapEntry(k.toString(), v)));
      }
    });
    return out;
  }
}
