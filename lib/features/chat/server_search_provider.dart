import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/models/session_search.dart';
import '../../domain/repositories/gateway_repository.dart';

/// Espera depois da última tecla antes de consultar o servidor. Substituível
/// nos testes.
final serverSearchDebounceProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 400),
);

/// Busca no conteúdo de todas as conversas, pelo Dashboard (A99).
///
/// Cada termo é uma instância; enquanto a pessoa digita, as instâncias
/// abandonadas morrem durante a espera e não chegam ao servidor. Sem
/// pareamento com o Dashboard falha com `StateError`.
final serverSearchProvider = FutureProvider.autoDispose
    .family<List<SessionSearchHit>, String>((ref, query) async {
      final GatewayRepository gateway;
      try {
        gateway = ref.watch(gatewayRepositoryProvider);
      } catch (_) {
        throw StateError('Dashboard não pareado.');
      }
      await Future<void>.delayed(ref.read(serverSearchDebounceProvider));
      if (!ref.mounted) return const [];
      return gateway.searchSessions(query);
    });
