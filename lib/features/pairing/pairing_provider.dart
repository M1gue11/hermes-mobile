import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateway_repository_provider.dart';
import '../../domain/models/platform_pairing.dart';
import '../../domain/repositories/gateway_repository.dart';

/// Pedidos de acesso e aprovados (A101). Sem Dashboard falha com
/// `StateError`.
final pairingProvider = FutureProvider.autoDispose<PairingState>((ref) {
  final GatewayRepository gateway;
  try {
    gateway = ref.watch(gatewayRepositoryProvider);
  } catch (_) {
    throw StateError('Dashboard não pareado.');
  }
  return gateway.pairing();
});

final pairingActionsProvider = Provider<PairingActions>(PairingActions.new);

class PairingActions {
  PairingActions(this._ref);

  final Ref _ref;

  Future<void> approve(PairingRequest request) =>
      _run((g) => g.approvePairing(request.platform, request.requestId));

  Future<void> revoke(PairedUser user) =>
      _run((g) => g.revokePairing(user.platform, user.userId));

  Future<void> clearPending() => _run((g) => g.clearPendingPairings());

  Future<void> _run(Future<Object?> Function(GatewayRepository g) call) async {
    try {
      await call(_ref.read(gatewayRepositoryProvider));
    } finally {
      // Mesmo na falha: um 404 quer dizer que a lista mudou no servidor.
      _ref.invalidate(pairingProvider);
    }
  }
}
