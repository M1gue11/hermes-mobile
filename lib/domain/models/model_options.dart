import 'hermes_provider.dart';
import 'model_lock.dart';

/// Resposta canônica de `GET /api/model/options`.
///
/// Além do catálogo, o Hermes informa o par efetivamente configurado no perfil.
/// Esse par é diferente do alias de compatibilidade anunciado por `/v1/models`
/// e é o que pode ser enviado a uma conta Codex via ChatGPT.
class ModelOptions {
  const ModelOptions({this.providers = const [], this.model, this.provider});

  final List<HermesProvider> providers;
  final String? model;
  final String? provider;

  ModelLock? get effective {
    final modelId = model?.trim();
    if (modelId == null || modelId.isEmpty) return null;
    final providerId = provider?.trim();
    return ModelLock(
      model: modelId,
      provider: providerId == null || providerId.isEmpty ? null : providerId,
    );
  }

  factory ModelOptions.fromJson(Map<String, dynamic> json) => ModelOptions(
    providers: _objectList(
      json['providers'],
    ).map(HermesProvider.fromJson).toList(growable: false),
    model: json['model']?.toString(),
    provider: json['provider']?.toString(),
  );

  static List<Map<String, dynamic>> _objectList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }
}
