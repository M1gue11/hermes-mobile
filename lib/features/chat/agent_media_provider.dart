import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/repositories/gateway_repository.dart';

/// Imagem entregue pelo agente (`MEDIA:<caminho>`), lida pelo Dashboard.
///
/// Sem pareamento com o Dashboard o provider falha com `StateError`, e a
/// figura mostra só a referência. Uma imagem lida fica em memória por alguns
/// minutos depois de sair da tela: rolar a conversa para cima e voltar não
/// deve baixar de novo até 25 MB.
final agentMediaProvider = FutureProvider.autoDispose.family<Uint8List, String>(
  (ref, path) {
    final GatewayRepository gateway;
    try {
      gateway = ref.watch(gatewayRepositoryProvider);
    } catch (_) {
      // O Riverpod embrulha a falha da dependência; a figura só precisa saber
      // que não há Dashboard.
      throw StateError('Dashboard não pareado.');
    }
    final link = ref.keepAlive();
    Timer? descarte;
    ref.onCancel(
      () => descarte = Timer(const Duration(minutes: 3), link.close),
    );
    ref.onResume(() => descarte?.cancel());
    ref.onDispose(() => descarte?.cancel());
    return gateway.agentMedia(path);
  },
);
