import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/hermes_repository_provider.dart';
import '../../domain/models/hermes_provider.dart';
import '../../domain/models/model_lock.dart';
import '../../domain/models/model_options.dart';

/// Inventário na tela, mais o que está acontecendo com ele.
class InventoryState {
  const InventoryState({
    required this.options,
    this.refreshing = false,
    this.refreshError,
  });

  final ModelOptions options;
  List<HermesProvider> get providers => options.providers;
  ModelLock? get effective => options.effective;

  /// Uma atualização ao vivo está em curso.
  final bool refreshing;

  /// A última atualização falhou. Separado do erro de carga porque perder a
  /// atualização não é o mesmo que não ter inventário nenhum.
  final Object? refreshError;

  InventoryState copyWith({
    ModelOptions? options,
    bool? refreshing,
    Object? refreshError,
    bool clearError = false,
  }) => InventoryState(
    options: options ?? this.options,
    refreshing: refreshing ?? this.refreshing,
    refreshError: clearError ? null : refreshError ?? this.refreshError,
  );
}

/// Inventário de providers e modelos, com gesto explícito de atualizar.
///
/// Vive fora do `bootState` de propósito. Medido em `hermes_cli/inventory.py`:
/// sem `refresh`, o servidor **não** sonda catálogo ao vivo e responde pelo
/// cache de disco, e é por isso que a maioria dos providers aparece com
/// `0 modelos`. Com `refresh`, ele re-busca o catálogo de cada provider e ainda
/// sonda os endpoints custom salvos, o que envolve rede de verdade e demora.
///
/// São duas operações de custo bem diferente, e a cara é a que o usuário tem de
/// pedir. Deixá-la no boot deixaria a abertura do app lenta para todo mundo por
/// causa de uma folha que quase ninguém abre.
class ModelInventory extends AsyncNotifier<InventoryState> {
  @override
  Future<InventoryState> build() async {
    final options = await ref.read(hermesRepositoryProvider).modelOptions();
    return InventoryState(options: options);
  }

  /// Re-busca o catálogo ao vivo. Só por gesto do usuário.
  Future<void> refresh() async {
    final atual = state.value;
    // Sem inventário na tela ainda, atualizar é o mesmo que carregar.
    if (atual == null) {
      ref.invalidateSelf();
      return;
    }
    state = AsyncData(atual.copyWith(refreshing: true, clearError: true));
    try {
      final options = await ref
          .read(hermesRepositoryProvider)
          .modelOptions(refresh: true);
      state = AsyncData(InventoryState(options: options));
    } catch (error) {
      // Falha ao atualizar **não** apaga o inventário que já estava bom: o
      // usuário perderia a lista inteira por causa de uma tentativa de melhorá-la.
      state = AsyncData(atual.copyWith(refreshing: false, refreshError: error));
    }
  }
}

final modelInventoryProvider =
    AsyncNotifierProvider<ModelInventory, InventoryState>(ModelInventory.new);
