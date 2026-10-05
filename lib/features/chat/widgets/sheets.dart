import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_scale.dart';
import '../../../core/theme/hermes_tokens.dart';
import '../../../core/widgets/failure_state.dart';
import '../../../core/widgets/hermes_sheet.dart';
import '../../../core/widgets/unicode_spinner.dart';
import '../../../data/hermes_repository_provider.dart';
import '../../../domain/models/conversation.dart';
import '../../../domain/models/hermes_failure.dart';
import '../../../domain/models/hermes_provider.dart';
import '../../../domain/models/model_lock.dart';
import '../../../domain/models/model_selection.dart';
import '../../settings/settings_provider.dart';
import '../../settings/agent_persona.dart';
import '../boot_provider.dart';
import '../chat_controller.dart';
import '../inventory_provider.dart';

/// Centraliza no botão de engrenagem os ajustes do cliente e recursos do gateway.
Future<void> showSettingsSheet(
  BuildContext context,
  WidgetRef ref, {
  bool canEditConnections = false,
}) {
  return showHermesSheet(
    context,
    title: 'Ajustes',
    tag: 'cliente',
    child: Column(
      children: [
        if (canEditConnections)
          _SettingsAction(
            icon: Icons.key_outlined,
            title: 'Conexões',
            subtitle: 'Endpoints e credenciais protegidas',
            onTap: () {
              context.push('/settings/connections');
            },
          ),
        _SettingsAction(
          icon: Icons.person_outline,
          title: 'Agente',
          subtitle: 'Nome e gênero usados pela interface',
          onTap: () {
            showAgentPersonaSheet(context, ref);
          },
        ),
        _SettingsAction(
          icon: Icons.forum_outlined,
          title: 'Conversa',
          subtitle: 'Atividade e organização dos turnos',
          onTap: () {
            showActivitySheet(context, ref);
          },
        ),
        _SettingsAction(
          icon: Icons.hub_outlined,
          title: 'Gateway',
          subtitle: 'Modelos, skills e toolsets efetivos',
          onTap: () {
            showGatewaySheet(context, ref);
          },
        ),
        _SettingsAction(
          icon: Icons.palette_outlined,
          title: 'Aparência',
          subtitle: 'Tema e animação do aplicativo',
          onTap: () {
            showAppearanceSheet(context, ref);
          },
        ),
        if (kDebugMode) ...[
          _SettingsAction(
            icon: Icons.article_outlined,
            title: 'Showcase Markdown',
            subtitle: 'Comparar o renderer com a referência do Obsidian',
            onTap: () {
              context.push('/debug/markdown-showcase');
            },
          ),
          _SettingsAction(
            icon: Icons.biotech_outlined,
            title: 'Captura de turno',
            subtitle: 'Comparar o stream ao vivo com a conversa reaberta',
            onTap: () {
              context.push('/debug/captura-de-turno');
            },
          ),
        ],
      ],
    ),
  );
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Icon(icon, color: t.dim),
      title: Text(title, style: t.serif.copyWith(color: t.ink)),
      subtitle: Text(
        subtitle,
        style: t.mono.copyWith(fontSize: 10, color: t.faint),
      ),
      trailing: Icon(Icons.chevron_right, color: t.faint),
      onTap: onTap,
    );
  }
}

// --- AGENTE -----------------------------------------------------------------

Future<void> showAgentPersonaSheet(BuildContext context, WidgetRef _) {
  return showHermesSheet(
    context,
    title: 'Agente',
    tag: 'persona',
    backTooltip: 'Voltar para Ajustes',
    child: const _AgentPersonaBody(),
  );
}

class _AgentPersonaBody extends ConsumerStatefulWidget {
  const _AgentPersonaBody();

  @override
  ConsumerState<_AgentPersonaBody> createState() => _AgentPersonaBodyState();
}

class _AgentPersonaBodyState extends ConsumerState<_AgentPersonaBody> {
  late final TextEditingController _name;
  AgentGender? _gender;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    _name = TextEditingController(text: settings.agentName);
    _gender = settings.agentGender;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final preview = AgentPersona(name: _name.text, gender: _gender);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Nome de exibição'),
        const SizedBox(height: 11),
        TextField(
          key: const ValueKey('agent-persona-name'),
          controller: _name,
          maxLength: 80,
          textCapitalization: TextCapitalization.words,
          style: t.serif.copyWith(fontSize: 15, color: t.ink),
          cursorColor: t.accent,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Hermes',
            helperText: 'Opcional. Vazio mantém Hermes como nome padrão.',
            filled: true,
            fillColor: t.codeBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.accent),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _sectionLabel(context, 'Gênero gramatical'),
        const SizedBox(height: 11),
        _SelectableRow(
          selected: _gender == null,
          onTap: () => setState(() => _gender = null),
          title: 'Não definir',
          subtitle: 'Usa frases neutras, sem adivinhar artigos ou pronomes.',
        ),
        _SelectableRow(
          selected: _gender == AgentGender.feminine,
          onTap: () => setState(() => _gender = AgentGender.feminine),
          title: 'Feminino',
          subtitle: 'Ex.: “Peça à ${preview.displayName}…”',
        ),
        _SelectableRow(
          selected: _gender == AgentGender.masculine,
          onTap: () => setState(() => _gender = AgentGender.masculine),
          title: 'Masculino',
          subtitle: 'Ex.: “Peça ao ${preview.displayName}…”',
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('save-agent-persona'),
            onPressed: () {
              ref
                  .read(appSettingsProvider.notifier)
                  .setAgentPersona(name: _name.text, gender: _gender);
              Navigator.of(context).pop();
            },
            child: const Text('Salvar agente'),
          ),
        ),
      ],
    );
  }
}

// --- DETALHES DA SESSÃO -----------------------------------------------------

Future<void> showConversationDetailsSheet(
  BuildContext context,
  WidgetRef ref, {
  required Conversation conversation,
  required List<Conversation> loadedConversations,
}) {
  return showHermesSheet(
    context,
    title: 'Detalhes da sessão',
    tag: 'gateway',
    child: _ConversationDetailsBody(
      initialConversation: conversation,
      loadedConversations: loadedConversations,
    ),
  );
}

class _ConversationDetailsBody extends ConsumerStatefulWidget {
  const _ConversationDetailsBody({
    required this.initialConversation,
    required this.loadedConversations,
  });

  final Conversation initialConversation;
  final List<Conversation> loadedConversations;

  @override
  ConsumerState<_ConversationDetailsBody> createState() =>
      _ConversationDetailsBodyState();
}

class _ConversationDetailsBodyState
    extends ConsumerState<_ConversationDetailsBody> {
  late final Future<Conversation> _detail;

  @override
  void initState() {
    super.initState();
    _detail = ref
        .read(hermesRepositoryProvider)
        .getConversation(widget.initialConversation.id);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return FutureBuilder<Conversation>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return FailureState(
            failure: hermesFailureFrom(snapshot.error),
            keyPrefix: 'detalhes',
            compact: true,
          );
        }
        final conversation = snapshot.data ?? widget.initialConversation;
        final parent = _loadedById(conversation.parentSessionId);
        final children = widget.loadedConversations
            .where((item) => item.parentSessionId == conversation.id)
            .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.title,
              style: tokens.serif.copyWith(fontSize: 19, color: tokens.ink),
            ),
            const SizedBox(height: 5),
            SelectableText(
              conversation.id,
              style: tokens.mono.copyWith(fontSize: 10.5, color: tokens.faint),
            ),
            const SizedBox(height: 22),
            _sectionLabel(context, 'Origem e atividade'),
            const SizedBox(height: 8),
            _GatewayValue(
              label: 'Origem',
              value: conversation.source ?? 'não informada',
            ),
            _GatewayValue(
              label: 'Modelo',
              value: conversation.model ?? 'não informado',
            ),
            _GatewayValue(
              label: 'Provider',
              value: conversation.provider ?? 'não informado',
            ),
            _GatewayValue(
              label: 'Iniciada',
              value: _sessionDate(conversation.startedAt),
            ),
            _GatewayValue(
              label: 'Última atividade',
              value: _sessionDate(conversation.lastActive),
            ),
            if (conversation.endReason != null)
              _GatewayValue(
                label: 'Encerramento',
                value: conversation.endReason!,
              ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'Uso'),
            const SizedBox(height: 8),
            _GatewayValue(
              label: 'Mensagens',
              value: '${conversation.messageCount}',
            ),
            _GatewayValue(
              label: 'Chamadas de ferramenta',
              value: '${conversation.toolCallCount}',
            ),
            _GatewayValue(
              label: 'Tokens de entrada',
              value: '${conversation.inputTokens}',
            ),
            _GatewayValue(
              label: 'Tokens de saída',
              value: '${conversation.outputTokens}',
            ),
            if (conversation.estimatedCostUsd != null)
              _GatewayValue(
                label: 'Custo estimado',
                value: _usd(conversation.estimatedCostUsd!),
              ),
            if (conversation.actualCostUsd != null)
              _GatewayValue(
                label: 'Custo real',
                value: _usd(conversation.actualCostUsd!),
              ),
            const SizedBox(height: 20),
            _sectionLabel(context, 'Lineage'),
            const SizedBox(height: 8),
            if (conversation.parentSessionId == null)
              Text(
                'Esta é uma sessão raiz.',
                style: tokens.serif.copyWith(fontSize: 13, color: tokens.dim),
              )
            else
              _LineageEntry(
                label: 'Derivada de',
                title: parent?.title ?? 'Sessão pai',
                id: conversation.parentSessionId!,
              ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Ramos carregados nesta lista',
                style: tokens.mono.copyWith(
                  fontSize: 10.5,
                  color: tokens.faint,
                ),
              ),
              const SizedBox(height: 6),
              for (final child in children)
                _LineageEntry(
                  label: 'Alternativa',
                  title: child.title,
                  id: child.id,
                ),
            ],
          ],
        );
      },
    );
  }

  Conversation? _loadedById(String? id) {
    if (id == null) return null;
    for (final item in widget.loadedConversations) {
      if (item.id == id) return item;
    }
    return null;
  }
}

class _LineageEntry extends StatelessWidget {
  const _LineageEntry({
    required this.label,
    required this.title,
    required this.id,
  });

  final String label;
  final String title;
  final String id;

  @override
  Widget build(BuildContext context) {
    final tokens = HermesTokens.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: tokens.bg2,
        border: Border.all(color: tokens.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: tokens.mono.copyWith(fontSize: 9.5, color: tokens.faint),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.serif.copyWith(color: tokens.ink),
          ),
          const SizedBox(height: 2),
          SelectableText(
            id,
            style: tokens.mono.copyWith(fontSize: 9.5, color: tokens.faint),
          ),
        ],
      ),
    );
  }
}

String _sessionDate(DateTime? raw) {
  final parsed = raw?.toLocal();
  if (parsed == null) return 'não informada';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
}

String _usd(num value) => 'US\$ ${value.toStringAsFixed(4)}';

// --- MODELO -----------------------------------------------------------------

/// Aplica a escolha de modelo e só fecha o sheet se o servidor aceitar.
///
/// Fechar antes da resposta esconderia a recusa: o usuário sairia achando que
/// escolheu. Quando o Hermes devolve `409 model_lock_unavailable`, o sheet fica
/// aberto e a razão aparece.
Future<void> _escolherModelo(
  BuildContext context,
  WidgetRef ref,
  ModelLock lock,
) async {
  final erro = await ref
      .read(chatControllerProvider.notifier)
      .setModel(lock.model, provider: lock.provider);
  if (!context.mounted) return;
  if (erro == null) {
    Navigator.of(context).pop();
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
}

Future<void> showModelSheet(BuildContext context, WidgetRef _) {
  return showHermesSheet(
    context,
    title: 'Modelo',
    tag: '/api/model/options',
    child: const _ModelSheetBody(),
  );
}

class _ModelSheetBody extends ConsumerWidget {
  const _ModelSheetBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = HermesTokens.of(context);
    final boot = ref.watch(bootStateProvider);
    final inventario = ref.watch(modelInventoryProvider);
    final selected = ref.watch(
      chatControllerProvider.select(
        (s) => (model: s.modelId, provider: s.modelProvider),
      ),
    );

    return boot.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: t.accent)),
      ),
      error: (e, _) => FailureState(
        failure: hermesFailureFrom(e),
        keyPrefix: 'modelos',
        compact: true,
        onRetry: () => ref.invalidate(bootStateProvider),
      ),
      data: (state) {
        final estado = inventario.value;
        final providers = estado?.providers ?? const <HermesProvider>[];
        final routableModels = state.models
            .where((model) => !isCompatibilityModelAlias(model.id))
            .toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (routableModels.isNotEmpty) ...[
              _sectionLabel(context, 'Modelos encaminháveis'),
              const SizedBox(height: 8),
              for (final m in routableModels)
                _SelectableRow(
                  selected: m.id == selected.model && selected.provider == null,
                  onTap: () =>
                      _escolherModelo(context, ref, ModelLock(model: m.id)),
                  title: m.id,
                  subtitle: m.ownedBy,
                ),
            ],

            // Modelos dos providers **conectados**. O inventário devolve o
            // universo inteiro, incluindo o que não está configurado, então
            // oferecer tudo seria oferecer escolha que falha no envio.
            for (final provider in providers.where(
              (item) => item.authenticated && item.models.isNotEmpty,
            )) ...[
              const SizedBox(height: 18),
              // "atual" qualifica o **provider**, então vive no rótulo da
              // seção. Repetido em cada linha, lia como se todo modelo dali
              // fosse o atual.
              _sectionLabel(
                context,
                provider.isCurrent ? '${provider.name} · atual' : provider.name,
              ),
              if (provider.freeTier) ...[
                const SizedBox(height: 4),
                Text(
                  'Conta em plano gratuito: os modelos pagos aparecem bloqueados.',
                  style: t.serif.copyWith(fontSize: 12, color: t.dim),
                ),
              ],
              const SizedBox(height: 8),
              for (final model in provider.models)
                _ModelOption(
                  key: ValueKey('modelo-${provider.id}-$model'),
                  provider: provider,
                  model: model,
                  selected:
                      model == selected.model &&
                      provider.id == selected.provider,
                  onTap: () => _escolherModelo(
                    context,
                    ref,
                    ModelLock(model: model, provider: provider.id),
                  ),
                ),
            ],

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _sectionLabel(context, 'Providers configurados'),
                ),
                _AtualizarCatalogo(
                  refreshing: estado?.refreshing ?? inventario.isLoading,
                  onTap: () =>
                      ref.read(modelInventoryProvider.notifier).refresh(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Falha e lista vazia não são a mesma coisa. Tratá-las igual foi o
            // que escondeu o A21.1: a tela culpava o gateway por não anunciar
            // nada, quando a chamada nem chegava ao lugar certo.
            if (estado == null && inventario.hasError)
              FailureState(
                failure: hermesFailureFrom(inventario.error),
                keyPrefix: 'inventario',
                compact: true,
                onRetry: () => ref.invalidate(modelInventoryProvider),
              )
            else if (estado == null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: t.accent),
                ),
              )
            else ...[
              // Atualizar falhou, mas o inventário anterior continua bom: a
              // lista fica, e o aviso explica por que ela não mudou.
              if (estado.refreshError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    key: const ValueKey('inventario-falha-atualizar'),
                    'Não foi possível atualizar o catálogo: '
                    '${hermesFailureFrom(estado.refreshError).title}. '
                    'A lista abaixo é a anterior.',
                    style: t.serif.copyWith(fontSize: 12.5, color: t.accentInk),
                  ),
                ),
              if (estado.providers.isEmpty)
                Text(
                  'Este Gateway ainda não anuncia o inventário de providers.',
                  style: t.serif.copyWith(fontSize: 13, color: t.dim),
                )
              else
                for (final provider in estado.providers)
                  _ProviderInventoryRow(provider: provider),
            ],
            const SizedBox(height: 8),
            Text(
              'Escolher um modelo trava a conversa nele no servidor. Provider não '
              'conectado não aparece como opção, e um par que esta instalação não '
              'sabe rotear é recusado em vez de trocado em silêncio. Atualizar '
              'busca o catálogo ao vivo de cada provider, o que demora.',
              style: t.serif.copyWith(fontSize: 12.5, color: t.dim),
            ),
          ],
        );
      },
    );
  }
}

/// Gesto de atualizar catálogo.
///
/// Existe porque, sem `refresh`, o servidor responde pelo cache e a maioria dos
/// providers mostra `0 modelos`. Enquanto roda, o rótulo muda: a busca ao vivo
/// sonda provider por provider e pode demorar, e um botão que parece inerte
/// convida ao segundo toque.
class _AtualizarCatalogo extends StatelessWidget {
  const _AtualizarCatalogo({required this.refreshing, required this.onTap});

  final bool refreshing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return InkWell(
      key: const ValueKey('atualizar-catalogo'),
      onTap: refreshing ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (refreshing)
              SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.accent,
                ),
              )
            else
              Icon(Icons.refresh, size: 14, color: t.accent),
            const SizedBox(width: 7),
            Text(
              refreshing ? 'BUSCANDO…' : 'ATUALIZAR',
              style: t.mono.copyWith(
                fontSize: 9.5,
                letterSpacing: 1.4,
                color: refreshing ? t.faint : t.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uma opção de modelo, com o que o servidor sabe sobre ela.
///
/// Modelo indisponível para a conta aparece **desabilitado e dizendo por quê**,
/// em vez de sumir: sumir esconderia que o modelo existe, e oferecer levaria a
/// uma recusa do backend depois do toque.
class _ModelOption extends StatelessWidget {
  const _ModelOption({
    super.key,
    required this.provider,
    required this.model,
    required this.selected,
    required this.onTap,
  });

  final HermesProvider provider;
  final String model;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bloqueado = provider.isUnavailable(model);
    final preco = provider.pricing[model];
    final caps = provider.capabilities[model];

    final detalhes = [
      provider.id,
      if (preco != null && !preco.isEmpty) preco.label,
      if (caps?.reasoning ?? false) 'raciocínio',
      if (caps?.fast ?? false) 'rápido',
    ].join(' · ');

    return Opacity(
      opacity: bloqueado ? 0.45 : 1,
      child: _SelectableRow(
        selected: selected,
        onTap: bloqueado ? null : onTap,
        title: model,
        subtitle: bloqueado
            ? '$detalhes · indisponível no plano gratuito'
            : detalhes,
      ),
    );
  }
}

/// Linha do inventário completo, incluindo provider que não dá para usar.
///
/// Provider não configurado continua aparecendo, mas agora **diz o que falta**,
/// com a frase que o próprio servidor mandou. Antes ele só se revelava
/// inutilizável na hora do envio.
class _ProviderInventoryRow extends StatelessWidget {
  const _ProviderInventoryRow({required this.provider});

  final HermesProvider provider;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final title = provider.isCurrent
        ? '${provider.name} · atual'
        : provider.name;
    final status = provider.authenticated ? 'conectado' : 'não autenticado';
    final falta = provider.setupHint;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: provider.isCurrent ? t.accent : t.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
        iconColor: t.accent,
        collapsedIconColor: t.faint,
        // O `ExpansionTile` do Material desenha um `Divider` em cima e embaixo
        // quando abre, e isso cortava o card com dois filetes cinzas por dentro
        // da nossa própria borda. O card já tem moldura; a de dentro é ruído.
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          title,
          style: t.serif.copyWith(fontSize: 14.5, color: t.ink),
        ),
        subtitle: Text(
          '${provider.totalModels} modelos · $status${provider.authType?.isNotEmpty == true ? ' · ${provider.authType}' : ''}',
          style: t.mono.copyWith(fontSize: 10.5, color: t.faint),
        ),
        children: [
          if (falta != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  key: ValueKey('provider-falta-${provider.id}'),
                  falta,
                  style: t.serif.copyWith(fontSize: 12.5, color: t.accentInk),
                ),
              ),
            ),
          if (provider.models.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                provider.authenticated
                    // Sem `refresh` o servidor responde pelo cache, e é por isso
                    // que provider conectado costuma mostrar zero modelo. Dizer
                    // isso vale mais que um "nenhum modelo" seco.
                    ? 'Nenhum modelo em cache. Toque em ATUALIZAR para buscar ao vivo.'
                    : 'Nenhum modelo anunciado.',
                style: t.serif.copyWith(fontSize: 13, color: t.dim),
              ),
            )
          else
            for (final model in provider.models)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: SelectableText(
                    model,
                    style: t.mono.copyWith(fontSize: 11.5, color: t.ink),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

// --- ATIVIDADE --------------------------------------------------------------

Future<void> showActivitySheet(BuildContext context, WidgetRef _) {
  return showHermesSheet(
    context,
    title: 'Conversa',
    tag: 'preferências',
    backTooltip: 'Voltar para Ajustes',
    child: Consumer(
      builder: (context, ref, _) {
        final t = HermesTokens.of(context);
        final showActivity = ref.watch(
          chatControllerProvider.select(
            (state) => state.reasoning.showActivity,
          ),
        );
        final chronological = ref.watch(
          appSettingsProvider.select(
            (settings) => settings.chronologicalActivity,
          ),
        );
        final ctrl = ref.read(chatControllerProvider.notifier);
        final settings = ref.read(appSettingsProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingsAction(
              icon: Icons.notes_outlined,
              title: 'Contexto da próxima run',
              subtitle: 'Instruções enviadas ao iniciar o próximo turno',
              onTap: () => showContextSheet(context, ref),
            ),
            const SizedBox(height: 18),
            _sectionLabel(context, 'Atividade'),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mostrar atividade',
                        style: t.serif.copyWith(fontSize: 15.5, color: t.ink),
                      ),
                      Text(
                        'Exibe eventos de ferramentas e atividade recebidos do gateway.',
                        style: t.serif.copyWith(fontSize: 13, color: t.dim),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: showActivity,
                  activeThumbColor: t.bg,
                  activeTrackColor: t.accent,
                  onChanged: ctrl.setShowActivity,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _sectionLabel(context, 'Organização do turno'),
            const SizedBox(height: 11),
            _SelectableRow(
              selected: chronological,
              onTap: () => settings.setChronologicalActivity(true),
              title: 'Cronológico',
              subtitle: 'Padrão. Cada evento aparece na ordem em que chegou.',
            ),
            _SelectableRow(
              selected: !chronological,
              onTap: () => settings.setChronologicalActivity(false),
              title: 'Consolidado',
              subtitle: 'Compacto. Atividade e ferramentas em dois blocos.',
            ),
          ],
        );
      },
    ),
  );
}

// --- CONTEXTO ---------------------------------------------------------------

Future<void> showContextSheet(BuildContext context, WidgetRef _) {
  return showHermesSheet(
    context,
    title: 'Contexto',
    tag: 'instructions',
    backTooltip: 'Voltar para Conversa',
    child: const _ContextBody(),
  );
}

class _ContextBody extends ConsumerStatefulWidget {
  const _ContextBody();

  @override
  ConsumerState<_ContextBody> createState() => _ContextBodyState();
}

class _ContextBodyState extends ConsumerState<_ContextBody> {
  late final TextEditingController _prompt;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(
      text: ref.read(chatControllerProvider).instructions,
    );
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final capabilities = ref
        .watch(bootStateProvider)
        .maybeWhen(
          data: (state) => state.capabilities.features,
          orElse: () => null,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(context, 'Instruções da próxima run'),
        const SizedBox(height: 11),
        TextField(
          controller: _prompt,
          maxLines: 5,
          style: t.serif.copyWith(fontSize: 14.5, height: 1.55, color: t.ink),
          cursorColor: t.accent,
          decoration: InputDecoration(
            hintText: 'Ex.: Responda em português, de forma objetiva.',
            hintStyle: t.serif.copyWith(fontSize: 14.5, color: t.faint),
            filled: true,
            fillColor: t.codeBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.line),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'O texto é enviado ao Hermes no campo instructions da próxima run.',
          style: t.serif.copyWith(fontSize: 13, color: t.dim),
        ),
        const SizedBox(height: 22),
        _sectionLabel(context, 'Capacidades do gateway'),
        const SizedBox(height: 11),
        _CapabilityRow(
          label: 'Sessões persistidas',
          enabled: capabilities?.sessionResources ?? false,
        ),
        _CapabilityRow(
          label: 'Skills disponíveis',
          enabled: capabilities?.skillsApi ?? false,
        ),
        _CapabilityRow(
          label: 'Memória editável por API',
          enabled: capabilities?.memoryWriteApi ?? false,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              ref
                  .read(chatControllerProvider.notifier)
                  .setInstructions(_prompt.text);
              Navigator.of(context).pop();
            },
            child: const Text('Salvar instruções'),
          ),
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 16,
            color: enabled ? t.positive : t.faint,
          ),
          const SizedBox(width: 10),
          Text(label, style: t.serif.copyWith(fontSize: 14, color: t.ink)),
        ],
      ),
    );
  }
}

// --- GATEWAY ----------------------------------------------------------------

Future<void> showGatewaySheet(BuildContext context, WidgetRef _) {
  return showHermesSheet(
    context,
    title: 'Gateway',
    tag: 'capabilities',
    backTooltip: 'Voltar para Ajustes',
    child: Consumer(
      builder: (context, ref, _) {
        final t = HermesTokens.of(context);
        final boot = ref.watch(bootStateProvider);
        return boot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => FailureState(
            failure: hermesFailureFrom(error),
            keyPrefix: 'gateway',
            compact: true,
            onRetry: () => ref.invalidate(bootStateProvider),
          ),
          data: (state) {
            final enabled = state.toolsets
                .where((item) => item.enabled)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(context, 'Runtime'),
                const SizedBox(height: 9),
                _GatewayValue(
                  label: 'Modelo padrão',
                  value: state.capabilities.model ?? 'não anunciado',
                ),
                _GatewayValue(
                  label: 'Modelos disponíveis',
                  value: '${state.models.length}',
                ),
                _GatewayValue(
                  label: 'Skills disponíveis',
                  value: '${state.skills.length}',
                ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'Toolsets ativos'),
                const SizedBox(height: 9),
                if (enabled.isEmpty)
                  Text(
                    'Nenhum toolset ativo foi anunciado.',
                    style: t.serif.copyWith(color: t.dim),
                  )
                else
                  for (final toolset in enabled)
                    _GatewayValue(
                      label: toolset.label.isEmpty
                          ? toolset.name
                          : toolset.label,
                      value:
                          '${toolset.tools.length} tools${toolset.configured ? ' · configurado' : ''}',
                    ),
                const SizedBox(height: 22),
                _sectionLabel(context, 'Skills carregadas'),
                const SizedBox(height: 9),
                for (final skill in state.skills.take(10))
                  _GatewayValue(
                    label: skill.name,
                    value: skill.category ?? 'sem categoria',
                  ),
                if (state.skills.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text(
                      '+ ${state.skills.length - 10} skills disponíveis no gateway',
                      style: t.mono.copyWith(fontSize: 11, color: t.faint),
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  state.capabilities.features.adminConfigRw
                      ? 'Este gateway permite configuração administrativa pela API.'
                      : 'Toolsets e providers são informativos: este gateway não expõe configuração administrativa pela API.',
                  style: t.serif.copyWith(fontSize: 13, color: t.dim),
                ),
              ],
            );
          },
        );
      },
    ),
  );
}

class _GatewayValue extends StatelessWidget {
  const _GatewayValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.serif.copyWith(fontSize: 14, color: t.ink),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 2,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: t.mono.copyWith(fontSize: 11, color: t.faint),
            ),
          ),
        ],
      ),
    );
  }
}

// --- APARÊNCIA --------------------------------------------------------------

Future<void> showAppearanceSheet(BuildContext context, WidgetRef _) {
  return showHermesSheet(
    context,
    title: 'Aparência',
    tag: 'settings',
    backTooltip: 'Voltar para Ajustes',
    child: Consumer(
      builder: (context, ref, _) {
        final t = HermesTokens.of(context);
        final settings = ref.watch(appSettingsProvider);
        final ctrl = ref.read(appSettingsProvider.notifier);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(context, 'Atmosfera'),
            const SizedBox(height: 11),
            for (final a in Atmosphere.values)
              _SelectableRow(
                selected: a == settings.atmosphere,
                onTap: () => ctrl.setAtmosphere(a),
                title: a.label,
                subtitle: a.note,
              ),
            const SizedBox(height: 22),
            _sectionLabel(context, 'Tamanho do texto'),
            const SizedBox(height: 11),
            for (final size in TextSize.values)
              _SelectableRow(
                selected: size == settings.textSize,
                onTap: () => ctrl.setTextSize(size),
                title: size.label,
                subtitle: size.note,
              ),
            const SizedBox(height: 22),
            _sectionLabel(context, 'Animação da marca'),
            const SizedBox(height: 11),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.25,
              children: [
                for (final name in kUnicodeSpinners.keys)
                  GestureDetector(
                    onTap: () => ctrl.setSpinner(name),
                    child: Container(
                      decoration: BoxDecoration(
                        color: name == settings.spinner
                            ? t.bg2
                            : Colors.transparent,
                        border: Border.all(
                          color: name == settings.spinner
                              ? t.accent.withValues(alpha: 0.5)
                              : t.line,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          UnicodeSpinner(
                            name: name,
                            size: 22,
                            color: name == settings.spinner
                                ? t.accentInk
                                : t.dim,
                            glow: name == settings.spinner ? t.accent : null,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.mono.copyWith(
                              fontSize: 9,
                              letterSpacing: 0.5,
                              color: name == settings.spinner ? t.ink : t.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

// --- helpers de UI ----------------------------------------------------------

Widget _sectionLabel(BuildContext context, String label) {
  final t = HermesTokens.of(context);
  return Text(
    label.toUpperCase(),
    style: t.mono.copyWith(fontSize: 10, letterSpacing: 1.6, color: t.faint),
  );
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.selected,
    required this.onTap,
    required this.title,
    this.subtitle,
  });

  final bool selected;

  /// Nulo desabilita a linha: opcao que o backend recusaria nao vira toque.
  final VoidCallback? onTap;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? t.bg2 : Colors.transparent,
          border: Border.all(
            color: selected ? t.accent.withValues(alpha: 0.45) : t.line,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.serif.copyWith(fontSize: 16, color: t.ink),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: t.mono.copyWith(fontSize: 11, color: t.faint),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? t.accent : t.faint,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.accent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
