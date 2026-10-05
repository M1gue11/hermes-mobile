import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/capabilities.dart';
import '../../domain/models/health_status.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/hermes_model.dart';
import '../../domain/models/hermes_skill.dart';
import '../../domain/models/hermes_toolset.dart';

part 'boot_provider.g.dart';

/// Estado de boot do app (record): servidor online? quais modelos? o que suporta?
/// Alimenta o indicador "Gateway · online", o model picker e o botão cancelar.
typedef BootState = ({
  bool online,
  List<HermesModel> models,
  List<HermesSkill> skills,
  List<HermesToolset> toolsets,
  Capabilities capabilities,
});

/// Faz a sequência de boot recomendada pela doc: `/health` + `/v1/capabilities`
/// + recursos efetivos. É um FutureProvider: a UI trata loading/erro/dados.
@riverpod
Future<BootState> bootState(Ref ref) async {
  final repo = ref.watch(hermesRepositoryProvider);

  final HealthStatus health;
  final Capabilities capabilities;
  final List<HermesModel> models;
  final List<HermesSkill> skills;
  final List<HermesToolset> toolsets;
  try {
    (health, capabilities, models, skills, toolsets) = await (
      repo.health(),
      repo.capabilities(),
      repo.models(),
      repo.skills(),
      repo.toolsets(),
    ).wait;
  } on ParallelWaitError catch (erro) {
    // O `.wait` de record embrulha as causas num `ParallelWaitError`, e sem
    // desembrulhar a tela diria "resposta inesperada" para uma simples queda de
    // rede. Aqui vale a **primeira** causa: as cinco chamadas vão para o mesmo
    // servidor, então quando uma cai por falta de alcance as outras caem pelo
    // mesmo motivo. Ver A7.
    final (a, b, c, d, e) =
        erro.errors as (AsyncError?, AsyncError?, AsyncError?, AsyncError?, AsyncError?);
    final primeira = [a, b, c, d, e].firstWhere((item) => item != null, orElse: () => null);
    throw hermesFailureFrom(primeira?.error);
  }
  return (
    online: health.online,
    models: models,
    skills: skills,
    toolsets: toolsets,
    capabilities: capabilities,
  );
}
