import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/hermes_chip.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/screen_top_bar.dart';
import '../../domain/models/server_health.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'server_provider.dart';

/// Leitura dos logs do servidor pelo Dashboard, do registro mais novo para o
/// mais antigo. A busca e o nível são aplicados no servidor, sobre as últimas
/// 2.000 linhas do arquivo.
class ServerLogsScreen extends ConsumerStatefulWidget {
  const ServerLogsScreen({super.key});

  @override
  ConsumerState<ServerLogsScreen> createState() => _ServerLogsScreenState();
}

class _ServerLogsScreenState extends ConsumerState<ServerLogsScreen> {
  final _busca = TextEditingController();
  Timer? _espera;
  LogQuery _query = (
    file: GatewayLogFile.agent,
    level: GatewayLogLevel.all,
    search: '',
  );

  @override
  void dispose() {
    _espera?.cancel();
    _busca.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _espera?.cancel();
    _espera = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || texto.trim() == _query.search) return;
      setState(
        () => _query = (
          file: _query.file,
          level: _query.level,
          search: texto.trim(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final logs = ref.watch(gatewayLogsProvider(_query));

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                ScreenTopBar(
                  title: 'Logs',
                  subtitle: 'DO MAIS NOVO PARA O MAIS ANTIGO',
                  onLeading: context.pop,
                  actions: [
                    IconButton(
                      key: const ValueKey('logs-refresh'),
                      tooltip: 'Atualizar',
                      onPressed: () =>
                          ref.invalidate(gatewayLogsProvider(_query)),
                      icon: Icon(Icons.refresh_rounded, size: 21, color: t.dim),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChipRow(
                        children: [
                          for (final file in GatewayLogFile.values)
                            HermesChip(
                              key: ValueKey('logs-file-${file.wire}'),
                              label: switch (file) {
                                GatewayLogFile.agent => 'Agente',
                                GatewayLogFile.errors => 'Erros',
                                GatewayLogFile.gateway => 'Gateway',
                              },
                              selected: _query.file == file,
                              minTapHeight: 48,
                              onTap: () => setState(
                                () => _query = (
                                  file: file,
                                  level: _query.level,
                                  search: _query.search,
                                ),
                              ),
                            ),
                        ],
                      ),
                      _ChipRow(
                        children: [
                          for (final level in GatewayLogLevel.values)
                            HermesChip(
                              key: ValueKey('logs-level-${level.wire}'),
                              label: switch (level) {
                                GatewayLogLevel.all => 'Tudo',
                                GatewayLogLevel.info => 'Info e acima',
                                GatewayLogLevel.warning => 'Avisos e erros',
                                GatewayLogLevel.error => 'Só erros',
                              },
                              selected: _query.level == level,
                              minTapHeight: 48,
                              onTap: () => setState(
                                () => _query = (
                                  file: _query.file,
                                  level: level,
                                  search: _query.search,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        key: const ValueKey('logs-search'),
                        controller: _busca,
                        onChanged: _buscar,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (texto) {
                          _espera?.cancel();
                          setState(
                            () => _query = (
                              file: _query.file,
                              level: _query.level,
                              search: texto.trim(),
                            ),
                          );
                        },
                        style: t.mono.copyWith(fontSize: 12.5, color: t.ink),
                        decoration: InputDecoration(
                          hintText: 'Buscar no log',
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: t.dim,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: t.line),
                Expanded(
                  child: switch (logs) {
                    AsyncValue(:final value?) => _LogList(
                      entries: value,
                      searching: _query.search.isNotEmpty,
                      onRefresh: () =>
                          ref.refresh(gatewayLogsProvider(_query).future),
                    ),
                    AsyncError(:final error) => _LogsMessage(
                      text: switch (error) {
                        StateError() => 'Conecte o Dashboard para ler os logs.',
                        GatewayAuthenticationRequired() =>
                          'Entre no Dashboard para ler os logs.',
                        GatewayOperationException(:final message) => message,
                        _ => 'Não foi possível ler o log.',
                      },
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList({
    required this.entries,
    required this.searching,
    required this.onRefresh,
  });

  final List<LogEntry> entries;
  final bool searching;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    if (entries.isEmpty) {
      return _LogsMessage(
        key: const ValueKey('logs-empty'),
        text: searching
            ? 'Nada encontrado nas últimas linhas deste log.'
            : 'Este log está vazio.',
      );
    }
    return RefreshIndicator(
      color: t.accent,
      backgroundColor: t.bg2,
      onRefresh: onRefresh,
      child: ListView.separated(
        key: const ValueKey('logs-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
        itemCount: entries.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: t.line),
        itemBuilder: (context, index) => _LogRow(entry: entries[index]),
      ),
    );
  }
}

class _LogRow extends StatefulWidget {
  const _LogRow({required this.entry});

  final LogEntry entry;

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  /// Registros mais longos que isto, quase sempre tracebacks, abrem
  /// recolhidos para não empurrar o resto da lista para longe. Conta também
  /// caracteres: uma linha lógica longa vira muitas na tela estreita.
  static const _linhasRecolhidas = 6;
  static const _caracteresRecolhidos = 420;

  var _aberto = false;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final entry = widget.entry;
    final linhas = entry.message.split('\n');
    final longo =
        linhas.length > _linhasRecolhidas ||
        entry.message.length > _caracteresRecolhidos;
    var texto = entry.message;
    if (longo && !_aberto) {
      texto = linhas.take(_linhasRecolhidas).join('\n');
      if (texto.length > _caracteresRecolhidos) {
        texto = '${texto.substring(0, _caracteresRecolhidos).trimRight()}…';
      }
    }
    final cor = switch (entry.level) {
      'ERROR' || 'CRITICAL' => t.accentInk,
      'WARNING' => t.ink,
      'DEBUG' => t.faint,
      _ => t.dim,
    };
    final at = entry.at;
    final hora = at == null
        ? null
        : '${_dois(at.hour)}:${_dois(at.minute)}:${_dois(at.second)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                if (hora != null) TextSpan(text: '$hora  '),
                if (entry.level case final level?)
                  TextSpan(
                    text: '$level  ',
                    style: TextStyle(color: cor),
                  ),
                if (entry.source case final source?) TextSpan(text: source),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.mono.copyWith(
              fontSize: 10,
              letterSpacing: 0.4,
              color: t.faint,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            texto,
            style: t.mono.copyWith(
              fontSize: 11.5,
              height: 1.5,
              color: entry.level == 'ERROR' || entry.level == 'CRITICAL'
                  ? t.ink
                  : t.ink.withValues(alpha: 0.86),
            ),
          ),
          if (longo)
            TextButton(
              key: const ValueKey('log-entry-toggle'),
              onPressed: () => setState(() => _aberto = !_aberto),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 40),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                _aberto
                    ? 'Recolher'
                    : linhas.length > 1
                    ? 'Mostrar tudo (${linhas.length} linhas)'
                    : 'Mostrar tudo',
                style: t.mono.copyWith(fontSize: 11, color: t.accent),
              ),
            ),
        ],
      ),
    );
  }
}

String _dois(int n) => n.toString().padLeft(2, '0');

class _LogsMessage extends StatelessWidget {
  const _LogsMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: t.serif.copyWith(fontSize: 15, height: 1.45, color: t.dim),
        ),
      ),
    );
  }
}

/// Uma linha de filtros que rola de lado, como os da lista de conversas: em
/// tela estreita os rótulos não quebram em pilha.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          children[i],
        ],
      ],
    ),
  );
}
