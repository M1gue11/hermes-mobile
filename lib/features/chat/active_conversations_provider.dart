import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/config/active_run_store.dart';

/// Armazenamento durável compartilhado entre a retomada e a lista.
final activeRunStoreProvider = Provider<ActiveRunStore>(
  (ref) => const SecureActiveRunStore(),
);

/// Índice leve das conversas que ainda têm um turno conhecido em andamento.
///
/// O estado nasce vazio para nunca atrasar a primeira pintura da lista. A
/// restauração segura acontece em segundo plano e é mesclada com atualizações
/// que tenham chegado enquanto a leitura estava em curso.
final activeConversationIdsProvider =
    NotifierProvider<ActiveConversationIds, Set<String>>(
      ActiveConversationIds.new,
    );

class ActiveConversationIds extends Notifier<Set<String>> {
  final Set<String> _removedDuringRestore = <String>{};
  bool _restoreFinished = false;

  @override
  Set<String> build() {
    _restoreFinished = false;
    _removedDuringRestore.clear();
    unawaited(_restore());
    return const <String>{};
  }

  Future<void> _restore() async {
    try {
      final restored = await ref
          .read(activeRunStoreProvider)
          .activeSessionIds();
      state = {
        ...restored.where((id) => !_removedDuringRestore.contains(id)),
        ...state,
      };
    } catch (_) {
      // O indicador é auxiliar; falha do keychain não bloqueia a lista.
    } finally {
      _restoreFinished = true;
      _removedDuringRestore.clear();
    }
  }

  void markActive(String sessionId) {
    _removedDuringRestore.remove(sessionId);
    if (state.contains(sessionId)) return;
    state = {...state, sessionId};
  }

  void markInactive(String sessionId) {
    if (!_restoreFinished) _removedDuringRestore.add(sessionId);
    if (!state.contains(sessionId)) return;
    state = {...state}..remove(sessionId);
  }
}
