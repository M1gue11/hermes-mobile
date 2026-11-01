import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../data/hermes_repository_provider.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/hermes_skill.dart';

/// Catálogo efetivo anunciado pelo API Server.
///
/// É separado do boot para que a tela tenha ciclo próprio de loading, falha e
/// atualização sem reiniciar inventário, modelos e capacidades do app inteiro.
///
/// Medido no Hermes 0.22.5: `/v1/skills` responde sempre `500` por um defeito
/// do servidor (chama `find_all_skills` com um argumento que não existe mais).
/// Quando o API Server falha assim, o mesmo catálogo vem do Dashboard. Se o
/// Dashboard também falhar, a causa mostrada continua sendo a do API Server.
final skillsCatalogProvider = FutureProvider.autoDispose<List<HermesSkill>>((
  ref,
) async {
  final api = ref.watch(hermesRepositoryProvider);
  // Lido antes do primeiro `await`: depois dele o `ref` pode já ter sido
  // descartado, e sem pareamento com o Dashboard o provider lança.
  Future<List<HermesSkill>> Function() dashboard;
  try {
    dashboard = ref.read(gatewayRepositoryProvider).skills;
  } catch (_) {
    dashboard = () => Future.error(StateError('Dashboard não pareado'));
  }

  final List<HermesSkill> skills;
  try {
    skills = await api.skills();
  } on HermesFailure catch (falha) {
    if (falha.kind != HermesFailureKind.servidorFalhou &&
        falha.kind != HermesFailureKind.naoEncontrado) {
      rethrow;
    }
    try {
      return _sorted(await dashboard());
    } catch (_) {
      throw falha;
    }
  }
  return _sorted(skills);
});

List<HermesSkill> _sorted(List<HermesSkill> skills) =>
    List<HermesSkill>.of(skills)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
