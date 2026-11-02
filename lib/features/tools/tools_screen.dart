import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../core/widgets/unicode_spinner.dart';
import '../../domain/models/server_tools.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'tools_provider.dart';

String _motivo(Object error) => switch (error) {
  StateError() => 'Conecte o Dashboard para gerenciar as ferramentas.',
  GatewayAuthenticationRequired() => 'Entre no Dashboard para continuar.',
  GatewayOperationException(:final message) => message,
  _ => 'Não foi possível falar com o Dashboard.',
};

/// Toolsets e servidores MCP do perfil (A100). Só liga, desliga e testa:
/// credenciais, variáveis e instalação ficam no computador.
class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final toolsets = ref.watch(toolsetSettingsProvider);
    final servers = ref.watch(mcpServersProvider);
    void atualizar() => ref
      ..invalidate(toolsetSettingsProvider)
      ..invalidate(mcpServersProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Ferramentas',
                  subtitle: 'TOOLSETS E SERVIDORES MCP',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('tools-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: atualizar,
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: t.accent,
                    backgroundColor: t.bg2,
                    onRefresh: () async {
                      atualizar();
                      await ref
                          .read(toolsetSettingsProvider.future)
                          .catchError((_) => const <ToolsetSetting>[]);
                    },
                    child: ListView(
                      key: const ValueKey('tools-list'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 44),
                      children: [
                        Text(
                          'As mudanças valem a partir da próxima conversa. '
                          'Credenciais e instalação ficam no computador.',
                          style: t.serif.copyWith(
                            fontSize: 14,
                            height: 1.45,
                            color: t.dim,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _label(t, 'Toolsets'),
                        switch (toolsets) {
                          AsyncValue(:final value?) when value.isEmpty => _note(
                            t,
                            'Nenhum toolset configurável.',
                          ),
                          AsyncValue(:final value?) => Column(
                            children: [
                              for (final toolset in value)
                                _ToolsetRow(
                                  key: ValueKey('toolset-${toolset.name}'),
                                  toolset: toolset,
                                ),
                            ],
                          ),
                          AsyncError(:final error) => _note(t, _motivo(error)),
                          _ => _note(t, 'Lendo…'),
                        },
                        const SizedBox(height: 30),
                        _label(t, 'Servidores MCP'),
                        switch (servers) {
                          AsyncValue(:final value?) when value.isEmpty => _note(
                            t,
                            'Nenhum servidor MCP configurado.',
                          ),
                          AsyncValue(:final value?) => Column(
                            children: [
                              for (final server in value)
                                _McpRow(
                                  key: ValueKey('mcp-${server.name}'),
                                  server: server,
                                ),
                            ],
                          ),
                          AsyncError(:final error) =>
                            // O motivo de não haver Dashboard já aparece
                            // nos toolsets; repetir só ocuparia a tela.
                            toolsets.hasError
                                ? const SizedBox.shrink()
                                : _note(t, _motivo(error)),
                          _ => _note(t, 'Lendo…'),
                        },
                      ],
                    ),
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

Widget _label(HermesTokens t, String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(
    text.toUpperCase(),
    style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.6, color: t.faint),
  ),
);

Widget _note(HermesTokens t, String text) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Text(
    text,
    style: t.serif.copyWith(fontSize: 14, height: 1.45, color: t.dim),
  ),
);

/// Chave que reflete o pedido na hora e volta atrás se o servidor recusar.
mixin _OptimisticToggle<W extends ConsumerStatefulWidget> on ConsumerState<W> {
  bool? requested;

  Future<void> toggle(
    bool enabled,
    Future<void> Function(ServerToolsActions actions) call,
  ) async {
    setState(() => requested = enabled);
    try {
      await call(ref.read(serverToolsActionsProvider));
    } catch (error) {
      if (!mounted) return;
      setState(() => requested = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_motivo(error))));
    }
  }
}

class _ToolsetRow extends ConsumerStatefulWidget {
  const _ToolsetRow({super.key, required this.toolset});

  final ToolsetSetting toolset;

  @override
  ConsumerState<_ToolsetRow> createState() => _ToolsetRowState();
}

class _ToolsetRowState extends ConsumerState<_ToolsetRow>
    with _OptimisticToggle {
  @override
  void didUpdateWidget(_ToolsetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.toolset.enabled == requested) requested = null;
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final toolset = widget.toolset;
    final enabled = requested ?? toolset.enabled;
    final meta = [
      toolset.toolCount == 1
          ? '1 ferramenta'
          : '${toolset.toolCount} ferramentas',
      if (!toolset.configured) 'sem credencial',
      if (toolset.platform != 'cli') 'só em ${toolset.platform}',
    ].join(' · ');
    return _SettingRow(
      title: Text(
        toolset.label,
        style: t.serif.copyWith(fontSize: 15.5, color: enabled ? t.ink : t.dim),
      ),
      description: toolset.description,
      meta: meta,
      metaAlert: !toolset.configured && enabled,
      toggle: Switch(
        key: ValueKey('toolset-switch-${toolset.name}'),
        value: enabled,
        activeThumbColor: t.bg,
        activeTrackColor: t.accent,
        onChanged: requested == null
            ? (value) => toggle(
                value,
                (actions) => actions.setToolset(toolset.name, enabled: value),
              )
            : null,
      ),
      semanticsLabel: '${toolset.label}, ${enabled ? 'ligado' : 'desligado'}',
    );
  }
}

class _McpRow extends ConsumerStatefulWidget {
  const _McpRow({super.key, required this.server});

  final McpServerSetting server;

  @override
  ConsumerState<_McpRow> createState() => _McpRowState();
}

class _McpRowState extends ConsumerState<_McpRow> with _OptimisticToggle {
  McpProbe? _sonda;
  var _testando = false;

  @override
  void didUpdateWidget(_McpRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.server.enabled == requested) requested = null;
  }

  Future<void> _testar() async {
    setState(() {
      _testando = true;
      _sonda = null;
    });
    McpProbe sonda;
    try {
      sonda = await ref
          .read(serverToolsActionsProvider)
          .testMcpServer(widget.server.name);
    } catch (error) {
      sonda = McpProbe(ok: false, error: _motivo(error));
    }
    if (!mounted) return;
    setState(() {
      _testando = false;
      _sonda = sonda;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final server = widget.server;
    final enabled = requested ?? server.enabled;
    final meta = [
      server.transport,
      ?server.auth,
      if (server.plugin case final plugin?) 'plugin $plugin',
    ].join(' · ');
    final sonda = _sonda;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingRow(
          title: Text(
            server.name,
            style: t.mono.copyWith(
              fontSize: 13,
              color: enabled ? t.ink : t.dim,
            ),
          ),
          meta: meta,
          toggle: Switch(
            key: ValueKey('mcp-switch-${server.name}'),
            value: enabled,
            activeThumbColor: t.bg,
            activeTrackColor: t.accent,
            onChanged: server.editable && requested == null
                ? (value) => toggle(
                    value,
                    (actions) =>
                        actions.setMcpServer(server.name, enabled: value),
                  )
                : null,
          ),
          semanticsLabel:
              '${server.name}, ${enabled ? 'ligado' : 'desligado'}'
              '${server.editable ? '' : ', fornecido por plugin'}',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              TextButton.icon(
                key: ValueKey('mcp-test-${server.name}'),
                onPressed: _testando ? null : _testar,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 40),
                ),
                icon: _testando
                    ? UnicodeSpinner(
                        name: 'helix',
                        size: 14,
                        color: t.accentInk,
                        glow: t.accent,
                      )
                    : Icon(Icons.cable_rounded, size: 16, color: t.accent),
                label: Text(
                  _testando ? 'Conectando…' : 'Testar conexão',
                  style: t.mono.copyWith(fontSize: 11, color: t.accent),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: motionOf(context, HermesMotion.revelar),
          curve: HermesMotion.curvaPadrao,
          alignment: Alignment.topLeft,
          child: sonda == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  key: ValueKey('mcp-probe-${server.name}'),
                  padding: const EdgeInsets.only(bottom: 12, left: 4),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          sonda.ok
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          size: 15,
                          color: sonda.ok ? t.positive : t.accentInk,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sonda.ok
                                ? 'Conectou · ${sonda.tools.length == 1 ? '1 ferramenta' : '${sonda.tools.length} ferramentas'}'
                                      '${sonda.tools.isEmpty ? '' : ': ${sonda.tools.take(6).join(', ')}${sonda.tools.length > 6 ? '…' : ''}'}'
                                : sonda.error ?? 'Não conectou.',
                            style: t.mono.copyWith(
                              fontSize: 11,
                              height: 1.45,
                              color: sonda.ok ? t.dim : t.accentInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.toggle,
    required this.semanticsLabel,
    this.description = '',
    this.meta = '',
    this.metaAlert = false,
  });

  final Widget title;
  final Widget toggle;
  final String semanticsLabel;
  final String description;
  final String meta;
  final bool metaAlert;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                label: semanticsLabel,
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.serif.copyWith(
                          fontSize: 13.5,
                          height: 1.4,
                          color: t.dim,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        meta,
                        style: t.mono.copyWith(
                          fontSize: 10.5,
                          color: metaAlert ? t.accentInk : t.faint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            toggle,
          ],
        ),
      ),
    );
  }
}
