import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../data/hermes_repository_provider.dart';
import '../../domain/models/hermes_skill.dart';
import '../../domain/repositories/gateway_repository.dart';

/// Catálogo de skills e se ele pode ser gerenciado pelo app.
///
/// [manageable] só é verdadeiro quando o catálogo veio do Dashboard, a única
/// superfície que lê o `SKILL.md`, reescreve e ativa/desativa.
typedef SkillsCatalog = ({List<HermesSkill> skills, bool manageable});

/// Catálogo de skills, separado do boot para que a tela tenha ciclo próprio
/// de loading, falha e atualização.
///
/// Com o Dashboard pareado e logado, ele é a fonte: lista também as
/// desativadas. Sem ele, o API Server lista só as ativas, em modo leitura. No
/// Hermes 0.22.5 `/v1/skills` responde sempre `500` por um defeito do
/// servidor; se o Dashboard também falhar, é essa causa que aparece.
final skillsCatalogProvider = FutureProvider.autoDispose<SkillsCatalog>((
  ref,
) async {
  final api = ref.watch(hermesRepositoryProvider);
  // Lido antes do primeiro `await`: depois dele o `ref` pode já ter sido
  // descartado, e sem pareamento com o Dashboard o provider lança.
  GatewayRepository? dashboard;
  try {
    dashboard = ref.watch(gatewayRepositoryProvider);
  } catch (_) {
    dashboard = null;
  }

  if (dashboard != null) {
    try {
      return (skills: _sorted(await dashboard.skills()), manageable: true);
    } catch (_) {
      // Sem sessão ou Dashboard fora do ar: o API Server ainda lista as ativas.
    }
  }
  return (skills: _sorted(await api.skills()), manageable: false);
});

/// `SKILL.md` integral, lido pelo Dashboard.
final skillContentProvider = FutureProvider.autoDispose.family<String, String>(
  (ref, name) => ref.watch(gatewayRepositoryProvider).skillContent(name),
);

enum SkillSaveResult { saved, changedOnServer }

/// Mutações de skills. Fica viva porque é usada depois de `await` por telas
/// que só a leem.
final skillManagementProvider = Provider<SkillManagement>(SkillManagement.new);

class SkillManagement {
  SkillManagement(this._ref);

  final Ref _ref;

  Future<void> setEnabled(String name, {required bool enabled}) async {
    await _ref
        .read(gatewayRepositoryProvider)
        .setSkillEnabled(name, enabled: enabled);
    _ref.invalidate(skillsCatalogProvider);
  }

  /// Grava [content] se o `SKILL.md` no servidor ainda for [baseline].
  ///
  /// O Dashboard não tem controle de versão: quem grava por último vence. A
  /// releitura antes de gravar é o que evita apagar sem aviso uma edição feita
  /// por outra pessoa ou pelo próprio agente enquanto o editor estava aberto.
  Future<SkillSaveResult> save(
    String name, {
    required String baseline,
    required String content,
    bool overwrite = false,
  }) async {
    final gateway = _ref.read(gatewayRepositoryProvider);
    if (!overwrite && await gateway.skillContent(name) != baseline) {
      return SkillSaveResult.changedOnServer;
    }
    await gateway.saveSkillContent(name, content);
    _ref
      ..invalidate(skillContentProvider(name))
      ..invalidate(skillsCatalogProvider);
    return SkillSaveResult.saved;
  }
}

List<HermesSkill> _sorted(List<HermesSkill> skills) =>
    List<HermesSkill>.of(skills)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
