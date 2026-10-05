import 'dart:async';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/widgets/failure_state.dart';
import '../../core/widgets/hermes_chip.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/tap_scale.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/hermes_failure.dart';
import 'boot_provider.dart';
import 'chat_controller.dart';
import 'conversation_actions_provider.dart';
import 'conversations_provider.dart';
import 'widgets/rename_conversation_dialog.dart';
import 'widgets/sheets.dart';

/// Como o topo da lista resume o alcance ao Hermes.
enum _Gateway {
  online('ONLINE'),
  offline('OFFLINE'),
  verificando('VERIFICANDO');

  const _Gateway(this.rotulo);
  final String rotulo;
}

/// Tela "Conversas" alimentada por `GET /api/sessions`.
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key, this.canEditConnections = false});

  final bool canEditConnections;

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  final _query = TextEditingController();
  final _searchFocus = FocusNode();
  var _discoveryOpen = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleDiscovery() {
    setState(() => _discoveryOpen = !_discoveryOpen);
    if (_discoveryOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      _searchFocus.unfocus();
    }
  }

  void _openChat(Conversation conversation) {
    unawaited(
      ref.read(chatControllerProvider.notifier).openConversation(conversation),
    );
    // `go`, e não `push`: `/chat` é filha de `/`, então navegar para ela monta
    // a pilha [lista, chat] de uma vez. Um `push` empilharia a lista de novo.
    context.go('/chat');
  }

  Future<void> _newChat() async {
    try {
      await ref.read(chatControllerProvider.notifier).newChat();
      if (mounted) context.go('/chat');
    } catch (error) {
      _showFailure('Não foi possível criar a conversa', error);
    }
  }

  /// Aviso curto de falha. O que aparece é o que aconteceu e o que fazer, nunca
  /// o `toString` da exceção. Ver A7.
  void _showFailure(String acao, Object error) {
    if (!mounted) return;
    final falha = hermesFailureFrom(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$acao. ${falha.title}: ${falha.hint}')),
    );
  }

  Future<void> _manage(
    Conversation conversation,
    _ConversationAction action,
  ) async {
    try {
      switch (action) {
        case _ConversationAction.details:
          final items = ref
              .read(conversationFeedProvider)
              .maybeWhen(
                data: (state) => state.items,
                orElse: () => const <Conversation>[],
              );
          await showConversationDetailsSheet(
            context,
            ref,
            conversation: conversation,
            loadedConversations: items,
          );
        case _ConversationAction.rename:
          final title = await _askTitle(conversation.title);
          if (title == null || title.isEmpty) return;
          await ref
              .read(conversationActionsProvider.notifier)
              .rename(conversation.id, title);
        case _ConversationAction.fork:
          await ref
              .read(conversationActionsProvider.notifier)
              .fork(conversation.id);
        case _ConversationAction.delete:
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Excluir conversa?'),
              content: Text(
                '“${conversation.title}” e o histórico serão removidos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Excluir'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref
                .read(conversationActionsProvider.notifier)
                .delete(conversation.id);
          }
      }
    } catch (error) {
      _showFailure('Não foi possível alterar a conversa', error);
    }
  }

  Future<String?> _askTitle(String current) async {
    return showRenameConversationDialog(context, currentTitle: current);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    final boot = ref.watch(bootStateProvider);
    // Três estados, não dois. Dizer OFFLINE enquanto a checagem ainda corre é
    // mentira barata, e é a primeira coisa que o dono do aparelho lê ao abrir.
    // Ver A7.
    final gateway = boot.when(
      data: (state) => state.online ? _Gateway.online : _Gateway.offline,
      loading: () => _Gateway.verificando,
      error: (_, _) => _Gateway.offline,
    );
    final feed = ref.watch(conversationFeedProvider);
    final activeConversationIds = ref.watch(activeConversationIdsProvider);
    final query = _query.text.trim().toLowerCase();

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: gateway == _Gateway.online
                                            ? tokens.positive
                                            : tokens.faint,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      'GATEWAY · ${gateway.rotulo}',
                                      style: tokens.mono.copyWith(
                                        fontSize: 10.5,
                                        letterSpacing: 2.2,
                                        color: tokens.faint,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Conversas',
                                  style: tokens
                                      .serifIn(FontWeight.w500)
                                      .copyWith(
                                        fontSize: 33,
                                        height: 1,
                                        color: tokens.ink,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          // A32: a máquina que roda o Hermes, alcançável da
                          // primeira tela, sem passar por Ajustes.
                          _CircleButton(
                            key: const ValueKey('botao-maquina'),
                            icon: Icons.terminal,
                            filled: false,
                            onTap: () => context.push('/maquina'),
                          ),
                          const SizedBox(width: 9),
                          _CircleButton(
                            icon: Icons.settings_outlined,
                            filled: false,
                            onTap: () => showSettingsSheet(
                              context,
                              ref,
                              canEditConnections: widget.canEditConnections,
                            ),
                          ),
                          const SizedBox(width: 9),
                          _CircleButton(
                            icon: Icons.add,
                            filled: true,
                            onTap: _newChat,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: feed.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _LoadError(
                      error: error,
                      // Refaz também a checagem de alcance: tentar de novo é
                      // dizer "veja se o Hermes voltou", e deixar o selo preso
                      // em OFFLINE depois de a lista voltar seria mentira.
                      onRetry: () {
                        ref.invalidate(bootStateProvider);
                        ref.invalidate(conversationFeedProvider);
                      },
                    ),
                    data: (state) {
                      final filtered = state.items
                          .where((conversation) {
                            if (query.isEmpty) return true;
                            return conversation.title.toLowerCase().contains(
                                  query,
                                ) ||
                                conversation.preview.toLowerCase().contains(
                                  query,
                                );
                          })
                          .toList(growable: false);
                      final groups = _groupConversations(filtered);
                      return RefreshIndicator(
                        color: tokens.accent,
                        onRefresh: () => ref
                            .read(conversationFeedProvider.notifier)
                            .refresh(),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification.metrics.extentAfter < 280) {
                              ref
                                  .read(conversationFeedProvider.notifier)
                                  .loadMore();
                            }
                            return false;
                          },
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 30),
                            children: [
                              _ConversationDiscovery(
                                expanded: _discoveryOpen,
                                controller: _query,
                                focusNode: _searchFocus,
                                sources: state.knownSources,
                                selected: state.selectedSource,
                                onToggle: _toggleDiscovery,
                                onClear: () {
                                  _query.clear();
                                  if (state.selectedSource != null) {
                                    unawaited(
                                      ref
                                          .read(
                                            conversationFeedProvider.notifier,
                                          )
                                          .selectSource(null),
                                    );
                                  }
                                },
                                onSelected: (source) => ref
                                    .read(conversationFeedProvider.notifier)
                                    .selectSource(source),
                              ),
                              if (filtered.isEmpty)
                                _EmptyConversationList(
                                  hasSearch:
                                      query.isNotEmpty ||
                                      state.selectedSource != null,
                                )
                              else
                                for (
                                  var groupIndex = 0;
                                  groupIndex < groups.length;
                                  groupIndex++
                                )
                                  _ConversationGroup(
                                    groupKey: groups[groupIndex].key,
                                    label: groups[groupIndex].label,
                                    items: groups[groupIndex].items,
                                    first: groupIndex == 0,
                                    activeConversationIds:
                                        activeConversationIds,
                                    onTap: _openChat,
                                    onManage: _manage,
                                  ),
                              if (state.loadingMore) const _LoadMoreProgress(),
                              if (state.loadMoreError != null)
                                _LoadMoreError(
                                  onRetry: () => ref
                                      .read(conversationFeedProvider.notifier)
                                      .loadMore(),
                                )
                              else if (state.hasMore && filtered.isNotEmpty)
                                const _LoadMoreHint(),
                            ],
                          ),
                        ),
                      );
                    },
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

typedef _ConversationGroupData = ({
  String key,
  String label,
  List<Conversation> items,
});

class _ConversationDiscovery extends StatelessWidget {
  const _ConversationDiscovery({
    required this.expanded,
    required this.controller,
    required this.focusNode,
    required this.sources,
    required this.selected,
    required this.onToggle,
    required this.onClear,
    required this.onSelected,
  });

  final bool expanded;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> sources;
  final String? selected;
  final VoidCallback onToggle;
  final VoidCallback onClear;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    final query = controller.text.trim();
    final active = query.isNotEmpty || selected != null;
    final summary = [if (query.isNotEmpty) '“$query”', ?selected].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TapScale(
                  key: const ValueKey('conversation-discovery-toggle'),
                  onTap: onToggle,
                  semanticsLabel: expanded
                      ? 'Recolher busca e filtros'
                      : 'Abrir busca e filtros',
                  pressedOverlayColor: tokens.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: tokens.accent),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            active ? summary : 'Buscar e filtrar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.mono.copyWith(
                              fontSize: 11,
                              letterSpacing: active ? 0.2 : 1.0,
                              color: active ? tokens.ink : tokens.dim,
                            ),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: tokens.accent,
                            ),
                          ),
                        ],
                        const SizedBox(width: 9),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0,
                          duration: motionOf(context, HermesMotion.estado),
                          curve: HermesMotion.curvaPadrao,
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: tokens.faint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (active)
                IconButton(
                  key: const ValueKey('conversation-discovery-clear'),
                  onPressed: onClear,
                  tooltip: 'Limpar busca e filtros',
                  icon: Icon(Icons.close, size: 18, color: tokens.faint),
                ),
            ],
          ),
          AnimatedSize(
            duration: motionOf(context, HermesMotion.revelar),
            curve: HermesMotion.curvaPadrao,
            alignment: Alignment.topCenter,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        Container(
                          key: const ValueKey('conversation-search-panel'),
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          decoration: BoxDecoration(
                            color: tokens.bg2,
                            border: Border.all(color: tokens.line),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: TextField(
                            key: const ValueKey('conversation-search-field'),
                            controller: controller,
                            focusNode: focusNode,
                            style: tokens.serif.copyWith(
                              fontSize: 14,
                              color: tokens.ink,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Título ou trecho da conversa',
                              hintStyle: tokens.serif.copyWith(
                                fontSize: 14,
                                color: tokens.faint,
                              ),
                            ),
                          ),
                        ),
                        _SourceFilterBar(
                          sources: sources,
                          selected: selected,
                          onSelected: onSelected,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SourceFilterBar extends StatelessWidget {
  const _SourceFilterBar({
    required this.sources,
    required this.selected,
    required this.onSelected,
  });

  final List<String> sources;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            HermesChip(
              label: 'Todas',
              selected: selected == null,
              minTapHeight: 48,
              onTap: () => onSelected(null),
            ),
            for (final source in sources) ...[
              const SizedBox(width: 7),
              HermesChip(
                label: source,
                selected: selected == source,
                minTapHeight: 48,
                onTap: () => onSelected(selected == source ? null : source),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadMoreProgress extends StatelessWidget {
  const _LoadMoreProgress();

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(color: tokens.accent),
        ),
      ),
    );
  }
}

class _LoadMoreHint extends StatelessWidget {
  const _LoadMoreHint();

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Center(
        child: Text(
          'Role para carregar mais',
          style: tokens.mono.copyWith(fontSize: 10.5, color: tokens.faint),
        ),
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(
            'Tentar carregar mais',
            style: tokens.mono.copyWith(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

List<_ConversationGroupData> _groupConversations(
  List<Conversation> conversations,
) {
  final groups = <DateTime?, List<Conversation>>{};
  for (final conversation in conversations) {
    final lastActive = conversation.lastActive?.toLocal();
    final date = lastActive == null
        ? null
        : DateTime(lastActive.year, lastActive.month, lastActive.day);
    (groups[date] ??= <Conversation>[]).add(conversation);
  }

  final dates = groups.keys.toList()
    ..sort((a, b) {
      if (a == null) return 1;
      if (b == null) return -1;
      return b.compareTo(a);
    });
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return [
    for (final date in dates)
      (
        key: date == null
            ? 'sem-data'
            : '${date.year}-${date.month.toString().padLeft(2, '0')}-'
                  '${date.day.toString().padLeft(2, '0')}',
        label: _calendarLabel(date, today),
        items: groups[date]!,
      ),
  ];
}

String _calendarLabel(DateTime? date, DateTime today) {
  if (date == null) return 'Sem data';
  if (date == today) return 'Hoje';
  if (date == today.subtract(const Duration(days: 1))) return 'Ontem';

  const weekdays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  const months = [
    'jan',
    'fev',
    'mar',
    'abr',
    'mai',
    'jun',
    'jul',
    'ago',
    'set',
    'out',
    'nov',
    'dez',
  ];
  final year = date.year == today.year ? '' : ' ${date.year}';
  return '${weekdays[date.weekday - 1]} · ${date.day} '
      '${months[date.month - 1]}$year';
}

class _ConversationGroup extends StatelessWidget {
  const _ConversationGroup({
    required this.groupKey,
    required this.label,
    required this.items,
    required this.first,
    required this.activeConversationIds,
    required this.onTap,
    required this.onManage,
  });

  final String groupKey;
  final String label;
  final List<Conversation> items;
  final bool first;
  final Set<String> activeConversationIds;
  final ValueChanged<Conversation> onTap;
  final void Function(Conversation, _ConversationAction) onManage;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Padding(
      key: ValueKey('conversation-group-$groupKey'),
      padding: EdgeInsets.only(top: first ? 2 : 22, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
            child: Text(
              label.toUpperCase(),
              style: tokens.mono.copyWith(
                fontSize: 10,
                letterSpacing: 1.8,
                color: tokens.faint,
              ),
            ),
          ),
          for (final conversation in items)
            _ConversationRow(
              key: ValueKey('conversation-row-${conversation.id}'),
              conversation: conversation,
              active: activeConversationIds.contains(conversation.id),
              onTap: () => onTap(conversation),
              onManage: (action) => onManage(conversation, action),
            ),
        ],
      ),
    );
  }
}

enum _ConversationAction { details, rename, fork, delete }

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    super.key,
    required this.conversation,
    required this.active,
    required this.onTap,
    required this.onManage,
  });

  final Conversation conversation;
  final bool active;
  final VoidCallback onTap;
  final ValueChanged<_ConversationAction> onManage;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return TapScale(
      onTap: onTap,
      pressedOverlayColor: tokens.accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Row(
                // O mock alinha pela linha de base. `CrossAxisAlignment.baseline`
                // não serve aqui porque o filete é pintura, não texto, e o `Row`
                // encosta no topo tudo que não tem linha de base: os pontos
                // subiam para cima das maiúsculas do título.
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // O título ocupa a largura natural dele, não uma fatia fixa
                  // da linha: é o que deixa o filete pontilhado esticar pelo
                  // vão que sobra, como no mock. O teto é a linha menos a cauda
                  // de largura fixa e o vão mínimo do filete, então nem o
                  // título mais longo empurra a hora para fora.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (constraints.maxWidth - _caudaDaLinha - 24)
                          .clamp(0.0, double.infinity),
                    ),
                    child: Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tokens
                          .serifIn(FontWeight.w500)
                          .copyWith(fontSize: 16.5, color: tokens.ink),
                    ),
                  ),
                  const Expanded(child: _TitleLeader()),
                  // A cauda vai com a largura natural: `_caudaDaLinha` é só o
                  // teto usado para dimensionar o título. Fixá-la aqui abriria
                  // um vão morto entre o fim do filete e a hora.
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _timeLabel(conversation.lastActive),
                        key: ValueKey('conversation-time-${conversation.id}'),
                        style: tokens.mono.copyWith(
                          fontSize: 10,
                          color: tokens.faint,
                        ),
                      ),
                      SizedBox.square(
                        dimension: 48,
                        child: PopupMenuButton<_ConversationAction>(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: tokens.faint,
                          ),
                          onSelected: onManage,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _ConversationAction.details,
                              child: Text('Detalhes'),
                            ),
                            PopupMenuItem(
                              value: _ConversationAction.rename,
                              child: Text('Renomear'),
                            ),
                            PopupMenuItem(
                              value: _ConversationAction.fork,
                              child: Text('Criar alternativa'),
                            ),
                            PopupMenuItem(
                              value: _ConversationAction.delete,
                              child: Text('Excluir'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1);
                final stackMetadata =
                    active && (constraints.maxWidth < 340 || textScale > 1.15);
                final preview = Text(
                  conversation.preview.isEmpty
                      ? 'Sem mensagens ainda'
                      : conversation.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokens.serif.copyWith(
                    fontSize: 13.5,
                    height: 1.4,
                    color: tokens.dim,
                  ),
                );
                final metadata = _ConversationMetadata(
                  conversationId: conversation.id,
                  model: conversation.model,
                  active: active,
                );

                if (stackMetadata) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      preview,
                      const SizedBox(height: 3),
                      Align(alignment: Alignment.centerRight, child: metadata),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: preview),
                    if (conversation.model != null || active) ...[
                      const SizedBox(width: 10),
                      metadata,
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Largura fixa da cauda da linha: a hora mais o botão de ações.
///
/// Fixa de propósito. É ela que torna exato o teto do título, e sem um teto
/// exato ou o título rouba metade da linha do filete (que é como o `Row` reparte
/// espaço entre filhos flexíveis) ou a hora sai empurrada para fora da tela.
/// Folgada o bastante para a hora crescer com o tamanho de fonte do sistema.
const double _caudaDaLinha = 110;

/// A condução pontilhada entre o título e a hora, como num sumário impresso.
///
/// `design/Hermes.dc.html`, `buildConvList`: um vão elástico com
/// `border-bottom:2px dotted color-mix(in oklab, var(--faint) 42%, transparent)`
/// e `margin:0 7px`. É ela que amarra as duas pontas da linha; sem ela a hora
/// fica solta ao lado do título e a lista perde o desenho editorial.
class _TitleLeader extends StatelessWidget {
  const _TitleLeader();

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Padding(
      // `margin:0 7px` e `transform:translateY(-3px)`: o filete corre um pouco
      // acima da linha de base, não no meio da caixa.
      padding: const EdgeInsets.only(left: 7, right: 7, bottom: 7),
      child: CustomPaint(
        size: const Size(double.infinity, 2),
        painter: _DottedLinePainter(tokens.faint.withValues(alpha: 0.42)),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    // Ponto de 2px a cada 4px: o mesmo ritmo do `dotted` de 2px do CSS.
    for (var x = 0.0; x < size.width; x += 4) {
      canvas.drawPoints(PointMode.points, [Offset(x, size.height / 2)], tinta);
    }
  }

  @override
  bool shouldRepaint(_DottedLinePainter old) => old.color != color;
}

String _timeLabel(DateTime? raw) {
  final parsed = raw?.toLocal();
  if (parsed == null) return '';
  return '${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}';
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Antes esta tela imprimia `'$error'`, que era o `toString` inteiro da
    // `DioException`. Ver A7.
    return FailureState(
      failure: hermesFailureFrom(error),
      onRetry: onRetry,
      keyPrefix: 'lista',
    );
  }
}

class _EmptyConversationList extends StatelessWidget {
  const _EmptyConversationList({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Center(
      child: Text(
        hasSearch ? 'Nenhuma conversa encontrada.' : 'Ainda não há conversas.',
        style: tokens.serif.copyWith(fontSize: 17, color: tokens.dim),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    super.key,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return TapScale(
      onTap: onTap,
      semanticsLabel: switch (icon) {
        Icons.terminal => 'Abrir máquina',
        Icons.settings_outlined => 'Abrir ajustes',
        Icons.add => 'Nova conversa',
        _ => 'Botão',
      },
      pressedOverlayColor: tokens.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? tokens.accent : tokens.bg2,
          border: filled ? null : Border.all(color: tokens.line),
        ),
        child: Icon(
          icon,
          size: filled ? 20 : 19,
          color: filled ? tokens.bg : tokens.dim,
        ),
      ),
    );
  }
}

class _ConversationMetadata extends StatelessWidget {
  const _ConversationMetadata({
    required this.conversationId,
    required this.model,
    required this.active,
  });

  final String conversationId;
  final String? model;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    final modelLabel = _compactModelLabel(model);
    final semantics = [
      if (modelLabel != null) 'Modelo $modelLabel',
      if (active) 'Resposta sendo gerada',
    ].join(', ');

    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (modelLabel != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 88),
              child: Text(
                modelLabel,
                key: ValueKey('conversation-model-$conversationId'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tokens.mono.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.25,
                  color: tokens.accent,
                ),
              ),
            ),
          if (modelLabel != null && active) ...[
            const SizedBox(width: 7),
            Text('·', style: tokens.mono.copyWith(color: tokens.faint)),
            const SizedBox(width: 7),
          ],
          if (active) const _ActiveConversationIndicator(),
        ],
      ),
    );
  }
}

String? _compactModelLabel(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  return value
      .replaceAll(RegExp(r'[_/]+'), ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toUpperCase()
      .replaceFirst(RegExp(r'^GPT '), '');
}

class _ActiveConversationIndicator extends StatelessWidget {
  const _ActiveConversationIndicator();

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tokens.accent,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'GERANDO',
          key: const ValueKey('active-conversation-indicator'),
          style: tokens.mono.copyWith(
            fontSize: 9,
            letterSpacing: 0.9,
            color: tokens.accent,
          ),
        ),
      ],
    );
  }
}
