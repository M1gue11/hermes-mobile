import 'hermes_model.dart';
import 'model_lock.dart';
import 'model_options.dart';

/// Alias OpenAI-compatible que representa o agente, não um LLM selecionável.
///
/// Mandá-lo como `model` para Codex com uma conta ChatGPT produz HTTP 400.
bool isCompatibilityModelAlias(String? id) => id?.trim() == 'hermes-agent';

/// Escolhe o par provider/modelo de uma conversa sem transformar alias em LLM.
///
/// Uma escolha concreta já gravada é preservada. Para conversa nova ou sessão
/// legada presa ao alias, o par efetivo de `/api/model/options` é a fonte
/// canônica. `/v1/models` só participa como último fallback quando anuncia um
/// id concreto; se houver apenas alias, omitir o override deixa o servidor usar
/// seu padrão e evita repetir o erro observado.
ModelLock? resolveModelLock({
  required ModelOptions options,
  ModelLock? preferred,
  List<HermesModel> advertised = const [],
}) {
  final preferredModel = preferred?.model.trim();
  final effective = options.effective;

  if (preferredModel != null &&
      preferredModel.isNotEmpty &&
      !isCompatibilityModelAlias(preferredModel)) {
    if ((preferred?.provider == null || preferred!.provider!.trim().isEmpty) &&
        effective?.model == preferredModel) {
      return effective;
    }
    return ModelLock(
      model: preferredModel,
      provider: preferred?.provider?.trim().isEmpty == true
          ? null
          : preferred?.provider?.trim(),
    );
  }

  if (effective != null && !isCompatibilityModelAlias(effective.model)) {
    return effective;
  }

  for (final model in advertised) {
    final id = model.id.trim();
    if (id.isNotEmpty && !isCompatibilityModelAlias(id)) {
      return ModelLock(model: id);
    }
  }
  return null;
}

/// Só a família `hermes-<geração>-<tamanho>` tem forma curta conhecida.
final _familiaHermes = RegExp(r'^hermes-(\d+)-(.+)$');

/// Rótulo curto do modelo para o cabeçalho da bolha e o chip do composer.
///
/// A abreviação existe para `hermes-4-70b` virar `H4 70B`. Aplicá-la a qualquer
/// id que comece com `hermes-` estragava os demais: `hermes-agent` virava
/// `H AGENT`, que lê pior que o próprio id. Fora do padrão, mostra o id como
/// veio, só em caixa alta.
String shortModelLabel(String? id) {
  final valor = id?.trim();
  if (valor == null || valor.isEmpty) return 'HERMES';
  final match = _familiaHermes.firstMatch(valor);
  if (match == null) return valor.toUpperCase();
  return 'H${match.group(1)} ${match.group(2)}'.toUpperCase();
}
