import 'package:flutter/material.dart';
import '../../connection/transport_notice.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/hermes_sheet.dart';
import '../../../domain/models/gateway_command.dart';
import '../../../domain/repositories/gateway_repository.dart';
import '../attachment_composer_controller.dart';
import '../gateway_commands_provider.dart';
import 'gateway_login_sheet.dart';

String commandError(Object error) => switch (error) {
  GatewayAuthenticationRequired(:final message) => message,
  GatewayOperationException(:final message) => message,
  FormatException() =>
    'Este Hermes devolveu um catálogo de comandos incompatível.',
  _ => 'Não foi possível consultar os comandos do Hermes.',
};

Future<String?> showGatewayCommandCatalog(
  BuildContext context,
  String sessionId,
) async {
  String? selected;
  await showHermesSheet(
    context,
    title: 'Comandos',
    tag: '',
    child: _CommandCatalog(
      sessionId: sessionId,
      onSelected: (command) {
        selected = '/${command.name}';
        Navigator.of(context).pop();
      },
    ),
  );
  return selected;
}

Future<void> showCommandOutput(
  BuildContext context,
  String command,
  String output,
) => showHermesSheet(
  context,
  title: command,
  tag: '',
  child: Builder(
    builder: (context) {
      final t = HermesTokens.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            output,
            style: t.serif.copyWith(fontSize: 15, height: 1.5, color: t.ink),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: t.dim,
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: output));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Resultado copiado')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copiar resultado'),
          ),
        ],
      );
    },
  ),
);

class _CommandCatalog extends ConsumerStatefulWidget {
  const _CommandCatalog({required this.sessionId, required this.onSelected});
  final String sessionId;
  final ValueChanged<GatewayCommand> onSelected;
  @override
  ConsumerState<_CommandCatalog> createState() => _CommandCatalogState();
}

class _CommandCatalogState extends ConsumerState<_CommandCatalog> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final provider = gatewayCommandCatalogProvider(widget.sessionId);
    final catalog = ref.watch(provider);
    final recent = ref
        .watch(gatewayCommandsProvider)
        .history
        .where((record) => record.sessionId == widget.sessionId)
        .take(5)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha um comando para revisar os argumentos antes de enviar.',
          style: t.serif.copyWith(fontSize: 14, height: 1.4, color: t.dim),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('gateway-command-search'),
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
          style: t.serif.copyWith(fontSize: 16, color: t.ink),
          decoration: InputDecoration(
            hintText: 'Buscar comando ou descrição',
            prefixIcon: Icon(Icons.search, color: t.dim),
            suffixIcon: IconButton(
              tooltip: 'Atualizar comandos',
              onPressed: () => ref.invalidate(provider),
              icon: Icon(Icons.refresh, color: t.dim),
            ),
          ),
        ),
        const SizedBox(height: 12),
        switch (catalog) {
          AsyncData(:final value) => Builder(
            builder: (context) {
              final rows = value.commands
                  .where(
                    (command) =>
                        '/${command.name} ${command.description} ${command.category}'
                            .toLowerCase()
                            .contains(_query),
                  )
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (value.warning.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Parte do catálogo não pôde ser carregada. Atualize para tentar novamente.',
                        style: t.serif.copyWith(
                          fontSize: 14,
                          color: t.accentInk,
                        ),
                      ),
                    ),
                  if (rows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        value.commands.isEmpty
                            ? 'O Hermes não anunciou comandos nesta sessão.'
                            : 'Nenhum comando encontrado.',
                        style: t.serif.copyWith(fontSize: 15, color: t.dim),
                      ),
                    ),
                  if (rows.isNotEmpty)
                    SizedBox(
                      height: (rows.length * 88.0).clamp(
                        0,
                        MediaQuery.sizeOf(context).height * .43,
                      ),
                      child: ListView.builder(
                        key: const ValueKey('gateway-command-list'),
                        itemCount: rows.length,
                        itemBuilder: (context, index) {
                          final command = rows[index];
                          final unavailable = command.unavailableReason;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 4,
                            ),
                            title: Text(
                              '/${command.name}',
                              style: t.mono.copyWith(
                                fontSize: 12,
                                color: t.ink,
                              ),
                            ),
                            subtitle: Text(
                              unavailable ?? command.description,
                              style: t.serif.copyWith(
                                fontSize: 14,
                                height: 1.4,
                                color: t.dim,
                              ),
                            ),
                            trailing: Icon(
                              unavailable == null
                                  ? Icons.north_west_rounded
                                  : Icons.desktop_windows_outlined,
                              size: 18,
                              color: t.dim,
                            ),
                            onTap: unavailable == null
                                ? () => widget.onSelected(command)
                                : null,
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
          AsyncError(:final error) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                commandError(error),
                style: t.serif.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: t.dim,
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (error is GatewayAuthenticationRequired) {
                    final entered = await showGatewayLoginSheet(
                      context,
                      authenticate: ref
                          .read(attachmentComposerControllerProvider.notifier)
                          .authenticate,
                    );
                    if (!entered || !mounted) return;
                    ref.invalidate(dashboardUsesCleartextProvider);
                  }
                  ref.invalidate(provider);
                },
                child: Text(
                  error is GatewayAuthenticationRequired
                      ? 'Conectar Dashboard'
                      : 'Tentar novamente',
                ),
              ),
            ],
          ),
          _ => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
        if (_query.isEmpty && recent.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Executados neste app',
            style: t.serif.copyWith(fontSize: 16, color: t.ink),
          ),
          for (final record in recent)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(
                record.command,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.mono.copyWith(fontSize: 11, color: t.ink),
              ),
              trailing: Icon(Icons.chevron_right, color: t.dim),
              onTap: () =>
                  showCommandOutput(context, record.command, record.output),
            ),
        ],
      ],
    );
  }
}

class GatewayCommandSuggestions extends ConsumerWidget {
  const GatewayCommandSuggestions({
    super.key,
    required this.sessionId,
    required this.text,
    required this.onSelected,
    required this.onOpenCatalog,
    required this.onDismiss,
  });
  final String sessionId;
  final String text;
  final void Function(String text, int replaceFrom) onSelected;
  final VoidCallback onOpenCatalog;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final completions = ref.watch(
      gatewayCommandCompletionsProvider((sessionId: sessionId, text: text)),
    );
    final catalog = ref.watch(gatewayCommandCatalogProvider(sessionId));
    if (completions.asData?.value.items.isEmpty == true && text.contains(' ')) {
      return const SizedBox.shrink();
    }
    final availableHeight =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      key: const ValueKey('gateway-command-suggestions'),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox(
          height: (availableHeight * .25).clamp(80, 190),
          child: Column(
            children: [
              Expanded(
                child: switch (completions) {
                  AsyncData(:final value) when value.items.isNotEmpty =>
                    ListView.builder(
                      itemCount: value.items.length,
                      itemBuilder: (context, index) {
                        final item = value.items[index];
                        final name = text.contains(RegExp(r'\s'))
                            ? parseSlashInvocation(text)?.name ?? ''
                            : item.text.replaceFirst(RegExp(r'^/+'), '');
                        final unavailable = catalog.asData?.value
                            .find(name)
                            ?.unavailableReason;
                        return ListTile(
                          dense: true,
                          minTileHeight: 48,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          title: Text(
                            text.contains(RegExp(r'\s'))
                                ? item.text
                                : '/${item.text.replaceFirst(RegExp(r'^/+'), '')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.mono.copyWith(fontSize: 12, color: t.ink),
                          ),
                          subtitle:
                              item.description.isEmpty && unavailable == null
                              ? null
                              : Text(
                                  unavailable ?? item.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.serif.copyWith(
                                    fontSize: 13,
                                    color: t.dim,
                                  ),
                                ),
                          trailing: unavailable == null
                              ? null
                              : Icon(
                                  Icons.desktop_windows_outlined,
                                  size: 18,
                                  color: t.dim,
                                ),
                          onTap: unavailable == null
                              ? () => onSelected(item.text, value.replaceFrom)
                              : null,
                        );
                      },
                    ),
                  AsyncData() => Center(
                    child: Text(
                      'Nenhuma sugestão para este trecho.',
                      style: t.serif.copyWith(color: t.dim),
                    ),
                  ),
                  AsyncError(:final error) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Text(
                        commandError(error),
                        style: t.serif.copyWith(color: t.dim),
                      ),
                    ),
                  ),
                  _ => Center(
                    child: Text(
                      'Consultando comandos…',
                      style: t.serif.copyWith(color: t.dim),
                    ),
                  ),
                },
              ),
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onOpenCatalog,
                        style: TextButton.styleFrom(foregroundColor: t.dim),
                        icon: const Icon(Icons.terminal, size: 16),
                        label: const Text('Todos os comandos'),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar sugestões',
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
