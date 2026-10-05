import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/hermes_skill.dart';

/// Catálogo efetivo anunciado pelo API Server.
///
/// É separado do boot para que a tela tenha ciclo próprio de loading, falha e
/// atualização sem reiniciar inventário, modelos e capacidades do app inteiro.
final skillsCatalogProvider = FutureProvider.autoDispose<List<HermesSkill>>((
  ref,
) async {
  final skills = await ref.watch(hermesRepositoryProvider).skills();
  return List<HermesSkill>.of(skills)
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});
