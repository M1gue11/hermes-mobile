import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/transport_security.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../data/config/dashboard_session_store.dart';

// Só estado de transporte chega à UI. Nenhuma chave/cookie integra o provider.
final apiUsesCleartextProvider = Provider<bool>((ref) => false);
final transportDashboardStoreProvider = Provider<DashboardSessionStore>(
  (ref) => const SecureDashboardSessionStore(),
);
final dashboardUsesCleartextProvider = FutureProvider<bool>((ref) async {
  final store = ref.watch(transportDashboardStoreProvider);
  final session = await store.read();
  if (session != null) return usesCleartext(session.baseUrl);
  return usesCleartext((await store.readCredentials())?.baseUrl ?? '');
});

class TransportWarning extends StatelessWidget {
  const TransportWarning({super.key, required this.url});
  final String url;
  @override
  Widget build(BuildContext context) {
    final warning = cleartextWarning(url);
    if (warning == null) return const SizedBox.shrink();
    return _Notice(title: 'Conexão sem TLS', text: warning);
  }
}

class ConnectionTransportNotice extends ConsumerWidget {
  const ConnectionTransportNotice({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiUsesCleartextProvider);
    final dashboard =
        ref.watch(dashboardUsesCleartextProvider).asData?.value ?? false;
    if (!api && !dashboard) return const SizedBox.shrink();
    final names = [
      if (api) 'API Server',
      if (dashboard) 'Dashboard',
    ].join(' e ');
    return _Notice(
      title: 'Conexão sem TLS',
      text:
          '$names em HTTP. Credenciais e mensagens dependem de VPN ou Tailscale '
          'para proteção no trajeto. Revise em Conexões.',
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.title, required this.text});
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.no_encryption_outlined, color: t.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.serif.copyWith(fontSize: 16, color: t.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: t.serif.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: t.dim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
