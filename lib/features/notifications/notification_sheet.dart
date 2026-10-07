import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/hermes_sheet.dart';
import '../../domain/models/operational_notice.dart';
import '../settings/settings_provider.dart';
import 'notification_inbox.dart';

Future<void> showNotificationSheet(BuildContext context) => showHermesSheet(
  context,
  title: 'Notificações',
  tag: 'local',
  backTooltip: 'Voltar para Ajustes',
  child: const NotificationSheet(),
);

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationInboxProvider);
    final persona = ref.watch(agentPersonaProvider);
    final tokens = HermesTokens.of(context);
    return ListenableBuilder(
      listenable: inbox,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Avisos de ${persona.displayName}',
            style: tokens.serif.copyWith(color: tokens.ink),
          ),
          Text(
            'Inbox e preferências apenas em memória nesta abertura do app. '
            'Recebe sinais da conversa conectada enquanto ela está visível. '
            'Sem entrega garantida em segundo plano, offline ou com o app encerrado.',
            style: tokens.mono.copyWith(fontSize: 11, color: tokens.dim),
          ),
          for (final category in NoticeCategory.values)
            SwitchListTile(
              key: ValueKey('notice-preference-${category.name}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _label(category),
                style: tokens.serif.copyWith(color: tokens.ink),
              ),
              value: inbox.enabled(category),
              onChanged: (value) => inbox.setEnabled(category, value),
            ),
          Text(
            '${inbox.unread} não lidas',
            style: tokens.mono.copyWith(color: tokens.dim),
          ),
          if (inbox.entries.isEmpty)
            Text(
              'Nenhum aviso local.',
              style: tokens.serif.copyWith(color: tokens.dim),
            ),
          for (final entry in inbox.entries)
            Padding(
              key: ValueKey('notice-entry-${entry.localId}'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_label(entry.category)} · ${entry.origin} · ${_severity(entry.level)}'
                    '${entry.read ? ' · Lida' : ' · Não lida'}',
                    style: tokens.mono.copyWith(
                      fontSize: 11,
                      color: tokens.dim,
                    ),
                  ),
                  // Text simples: nenhum Markdown, link remoto ou ação do payload.
                  Text(
                    entry.text,
                    style: tokens.serif.copyWith(color: tokens.ink),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        key: ValueKey('notice-open-${entry.localId}'),
                        onPressed: () {
                          inbox.markRead(entry.localId);
                          final router = GoRouter.of(context);
                          // Fecha inbox e Ajustes antes de trocar a conversa durável.
                          Navigator.of(
                            context,
                          ).popUntil((route) => route is! PopupRoute);
                          router.go(entry.location);
                        },
                        child: const Text('Abrir conversa'),
                      ),
                      if (!entry.read)
                        TextButton(
                          onPressed: () => inbox.markRead(entry.localId),
                          child: const Text('Marcar lida'),
                        ),
                      TextButton(
                        onPressed: () => inbox.remove(entry.localId),
                        child: const Text('Remover'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _label(NoticeCategory category) => switch (category) {
  NoticeCategory.progress => 'Progresso',
  NoticeCategory.completion => 'Conclusão e interrupção',
  NoticeCategory.error => 'Erro',
  NoticeCategory.custom => 'Personalizado',
};

String _severity(NoticeLevel level) => switch (level) {
  NoticeLevel.info => 'Informação',
  NoticeLevel.success => 'Sucesso',
  NoticeLevel.warning => 'Atenção',
  NoticeLevel.error => 'Erro',
};
