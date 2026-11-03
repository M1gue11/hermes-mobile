import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/hermes_sheet.dart';
import 'sheets.dart';

/// Capacidades para preparar o trabalho, próximas do compositor. As telas de
/// gestão mantêm explícito o alcance das mudanças no perfil do Hermes.
Future<void> showChatResourcesSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onCommands,
}) async {
  String? destination;
  void open(String route) {
    destination = route;
    Navigator.of(context).pop();
  }

  await showHermesSheet(
    context,
    title: 'Recursos',
    tag: '',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onCommands != null)
          _ActionRow(
            icon: Icons.terminal_rounded,
            title: 'Comandos',
            description: 'Consultar comandos e preparar uma ação na conversa',
            onTap: () => open('commands'),
          ),
        _ActionRow(
          icon: Icons.auto_stories_outlined,
          title: 'Skills',
          description: 'Consultar e gerenciar habilidades do agente',
          onTap: () => open('/skills'),
        ),
        _ActionRow(
          icon: Icons.handyman_outlined,
          title: 'Ferramentas e MCP',
          description: 'Configurar o perfil para novas conversas',
          onTap: () => open('/tools'),
        ),
        _ActionRow(
          icon: Icons.notes_outlined,
          title: 'Instruções do próximo turno',
          description: 'Orientações enviadas com a próxima mensagem',
          onTap: () => showContextSheet(
            context,
            ref,
            title: 'Instruções',
            backTooltip: 'Voltar para Recursos',
          ),
        ),
      ],
    ),
  );
  if (destination != null && context.mounted) {
    if (destination == 'commands') {
      onCommands?.call();
    } else {
      await context.push(destination!);
    }
  }
}

/// Administração do Hermes acessível sem voltar à lista de conversas.
Future<void> showHermesOperationsSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool canEditConnections,
}) async {
  String? destination;
  void open(String route) {
    destination = route;
    Navigator.of(context).pop();
  }

  await showHermesSheet(
    context,
    title: 'Hermes',
    tag: '',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionRow(
          icon: Icons.how_to_reg_outlined,
          title: 'Acessos',
          description: 'Pedidos e usuários de plataformas de mensagem',
          onTap: () => open('/pairing'),
        ),
        _ActionRow(
          icon: Icons.insights_outlined,
          title: 'Uso geral',
          description: 'Tokens e custo de todas as conversas por período',
          onTap: () => open('/usage'),
        ),
        _ActionRow(
          icon: Icons.schedule_outlined,
          title: 'Agendamentos',
          description: 'Rotinas que o agente executa sozinho',
          onTap: () => open('/jobs'),
        ),
        _ActionRow(
          icon: Icons.monitor_heart_outlined,
          title: 'Servidor',
          description: 'Saúde, logs e reinício do gateway',
          onTap: () => open('/server'),
        ),
        Divider(color: HermesTokens.of(context).line, height: 24),
        _ActionRow(
          icon: Icons.settings_outlined,
          title: 'Ajustes do aplicativo',
          description: 'Conexões, persona, aparência e preferências',
          onTap: () => open('settings'),
        ),
      ],
    ),
  );
  if (!context.mounted || destination == null) return;
  if (destination == 'settings') {
    await showSettingsSheet(
      context,
      ref,
      canEditConnections: canEditConnections,
    );
  } else {
    await context.push(destination!);
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      minLeadingWidth: 28,
      leading: Icon(icon, size: 22, color: t.dim),
      title: Text(title, style: t.serif.copyWith(fontSize: 16, color: t.ink)),
      subtitle: Text(
        description,
        style: t.serif.copyWith(fontSize: 13, height: 1.4, color: t.dim),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: t.dim),
      onTap: onTap,
    );
  }
}
