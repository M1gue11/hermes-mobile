import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/hermes_motion.dart';
import '../../core/theme/hermes_radius.dart';
import '../../core/theme/hermes_tokens.dart';
import '../../core/router/hermes_route_observer.dart';
import '../../core/widgets/failure_state.dart';
import '../../core/widgets/hermes_chip.dart';
import '../../core/widgets/paper_texture.dart';
import '../../core/widgets/tap_scale.dart';
import '../../core/widgets/unicode_spinner.dart';
import '../../domain/models/approval_request.dart';
import '../../domain/models/attachment_envelope.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/clarify_request.dart';
import '../../domain/models/composer_attachment.dart';
import '../../domain/models/conversation_search.dart';
import '../../domain/models/model_selection.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../settings/settings_provider.dart';
import '../settings/agent_persona.dart';
import 'attachment_composer_controller.dart';
import 'boot_provider.dart';
import 'chat_controller.dart';
import 'chat_drafts_provider.dart';
import 'chat_thread_scroll_controller.dart';
import 'widgets/chat_thread_view.dart';
import 'widgets/message_bubbles.dart';
import 'widgets/gateway_login_sheet.dart';
import 'widgets/sheets.dart';

/// Tela de conversa com o agente. Mostra a thread (raciocínio + tools + texto),
/// o composer e a barra de streaming. Lê tudo do [ChatController].
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver, RouteAware {
  final _input = TextEditingController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _threadScroll = ChatThreadScrollController();
  final _messageKeys = <String, GlobalKey>{};

  ScrollController get _scroll => _threadScroll.position;

  /// Busca é estado efêmero desta tela: não muda a conversa nem vai ao servidor.
  var _searching = false;
  var _searchCursor = 0;
  var _searchSeekEpoch = 0;

  /// Primeira escolha bloqueia as demais até o servidor responder.
  ApprovalChoice? _approvalInFlight;
  String? _clarificationInFlight;
  Timer? _recordingTimer;
  var _recordingElapsed = Duration.zero;
  String? _draftSessionId;
  var _restoringDraft = false;
  PageRoute<dynamic>? _observedRoute;
  ChatController? _chatController;
  var _routeVisible = true;
  var _appVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appVisible =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    try {
      _chatController = ref.read(chatControllerProvider.notifier);
    } catch (_) {
      // Alguns catálogos e testes visuais injetam um ChatState estático. Neles
      // não há listener real para coordenar.
    }
    _input.addListener(_inputChanged);
    ref.listenManual<String?>(
      chatControllerProvider.select((state) => state.sessionId),
      (_, sessionId) => _restoreDraft(sessionId),
      fireImmediately: true,
    );
    _syncLiveUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is! PageRoute<dynamic> || identical(route, _observedRoute)) {
      return;
    }
    final previous = _observedRoute;
    if (previous != null) hermesRouteObserver.unsubscribe(this);
    _observedRoute = route;
    hermesRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    _routeVisible = false;
    _syncLiveUpdates();
    WidgetsBinding.instance.removeObserver(this);
    if (_observedRoute != null) hermesRouteObserver.unsubscribe(this);
    _recordingTimer?.cancel();
    _input.removeListener(_inputChanged);
    _input.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _threadScroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
    _syncLiveUpdates();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _syncLiveUpdates();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncLiveUpdates();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncLiveUpdates();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _syncLiveUpdates();
  }

  void _syncLiveUpdates() {
    final controller = _chatController;
    if (controller == null) return;
    unawaited(controller.setLiveUpdatesVisible(_routeVisible && _appVisible));
  }

  void _inputChanged() {
    if (!_restoringDraft) {
      ref
          .read(chatDraftsProvider.notifier)
          .update(_draftSessionId, _input.text);
    }
    setState(() {});
  }

  void _restoreDraft(String? sessionId) {
    if (_draftSessionId == sessionId) return;
    _draftSessionId = sessionId;
    final draft = ref.read(chatDraftsProvider.notifier).draftFor(sessionId);
    _restoringDraft = true;
    _input.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
    _restoringDraft = false;
  }

  /// Voltar ao fim por gesto explícito: reata o acompanhamento.
  void _resumeFollowing() {
    unawaited(
      _threadScroll.animateToEnd(
        duration: motionOf(context, HermesMotion.estado),
        curve: HermesMotion.curvaPadrao,
      ),
    );
  }

  void _pauseFollowing() => _threadScroll.pauseFollowing();

  Future<void> _send() async {
    final text = _input.text.trim();
    final chat = ref.read(chatControllerProvider);
    final attachments = ref.read(attachmentComposerControllerProvider);
    if ((text.isEmpty && attachments.attachments.isEmpty) ||
        attachments.busy ||
        attachments.recording ||
        chat.sessionId == null) {
      return;
    }

    String prepared;
    try {
      prepared = await _prepareAttachmentInput(chat.sessionId!, text);
    } on GatewayAuthenticationRequired {
      if (!mounted) return;
      final controller = ref.read(
        attachmentComposerControllerProvider.notifier,
      );
      final authenticated = await showGatewayLoginSheet(
        context,
        authenticate: controller.authenticate,
      );
      if (!authenticated || !mounted) return;
      try {
        prepared = await _prepareAttachmentInput(chat.sessionId!, text);
      } on GatewayAuthenticationRequired catch (error) {
        _showComposerError(error.message);
        return;
      } on GatewayOperationException catch (error) {
        _showComposerError(error.message);
        return;
      }
    } on GatewayOperationException catch (error) {
      _showComposerError(error.message);
      return;
    }

    final submitted = await ref
        .read(chatControllerProvider.notifier)
        .send(prepared);
    if (!submitted || !mounted) return;
    ref.read(attachmentComposerControllerProvider.notifier).clear();
    if (_draftSessionId == chat.sessionId) _input.clear();
    // Quem acabou de falar quer ver a própria mensagem e a resposta.
    _resumeFollowing();
  }

  Future<String> _prepareAttachmentInput(String sessionId, String text) => ref
      .read(attachmentComposerControllerProvider.notifier)
      .prepareInput(storedSessionId: sessionId, caption: text);

  void _showComposerError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleRecording() async {
    final controller = ref.read(attachmentComposerControllerProvider.notifier);
    final attachmentState = ref.read(attachmentComposerControllerProvider);
    if (attachmentState.recording) {
      _recordingTimer?.cancel();
      await controller.stopRecording();
      if (mounted) setState(() => _recordingElapsed = Duration.zero);
      return;
    }
    await controller.startRecording();
    if (!mounted || !ref.read(attachmentComposerControllerProvider).recording) {
      return;
    }
    setState(() => _recordingElapsed = Duration.zero);
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _recordingElapsed += const Duration(seconds: 1));
      if (_recordingElapsed.inMinutes >= 10) _toggleRecording();
    });
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await ref
        .read(attachmentComposerControllerProvider.notifier)
        .cancelRecording();
    if (mounted) setState(() => _recordingElapsed = Duration.zero);
  }

  void _toggleSearch() {
    if (_searching) {
      _closeSearch();
      return;
    }
    setState(() {
      _searching = true;
      _searchCursor = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    _searchSeekEpoch++;
    _searchFocus.unfocus();
    _search.clear();
    setState(() {
      _searching = false;
      _searchCursor = 0;
    });
  }

  void _searchChanged(String _) {
    setState(() => _searchCursor = 0);
    _scheduleRevealSearchHit();
  }

  void _moveSearch(int delta) {
    final messages = ref.read(chatControllerProvider).messages;
    final hits = conversationSearchMatches(messages, _search.text);
    if (hits.isEmpty) return;
    setState(() {
      _searchCursor = (_searchCursor + delta) % hits.length;
      if (_searchCursor < 0) _searchCursor += hits.length;
    });
    _scheduleRevealSearchHit();
  }

  void _scheduleRevealSearchHit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealCurrentSearchHit();
    });
  }

  /// Localiza também um item ainda não construído pelo `ListView.builder`.
  ///
  /// A lista continua virtualizada no uso normal. Durante a busca, saltamos por
  /// estimativa e refinamos usando o intervalo de índices que o sliver construiu
  /// naquele quadro; quando o alvo existe na árvore, `ensureVisible` faz o
  /// alinhamento final. Assim A25 não desfaz a correção de desempenho do A3.
  Future<void> _revealCurrentSearchHit() async {
    final epoch = ++_searchSeekEpoch;
    final messages = ref.read(chatControllerProvider).messages;
    final hits = conversationSearchMatches(messages, _search.text);
    if (!_searching || hits.isEmpty || !_scroll.hasClients) return;
    // Buscar é uma intenção de releitura. O salto nunca deve deixar a thread
    // voltar a perseguir o streaming só porque terminou perto do rodapé.
    _threadScroll.pauseFollowing();
    final cursor = _searchCursor.clamp(0, hits.length - 1);
    final target = hits[cursor];
    final max = _scroll.position.maxScrollExtent;
    if (messages.length > 1) {
      _scroll.jumpTo(max * target / (messages.length - 1));
    }

    // Na lista cronológica, índices e offsets crescem na mesma direção. Os
    // limites abaixo refinam a estimativa sem assumir alturas iguais.
    var earlierIndex = 0;
    var earlierOffset = 0.0;
    var laterIndex = messages.length - 1;
    var laterOffset = max;

    for (var attempt = 0; attempt < 14; attempt++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || epoch != _searchSeekEpoch || !_scroll.hasClients) return;

      final targetContext = _keyFor(messages[target]).currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.18,
          duration: motionOf(context, HermesMotion.superficie),
          curve: HermesMotion.curvaPadrao,
        );
        return;
      }

      final built = <int>[
        for (var index = 0; index < messages.length; index++)
          if (_keyFor(messages[index]).currentContext != null) index,
      ];
      if (built.isEmpty) return;
      final first = built.first;
      final last = built.last;
      final current = _scroll.offset;
      if (target < first) {
        laterIndex = first;
        laterOffset = current;
      } else if (target > last) {
        earlierIndex = last;
        earlierOffset = current;
      } else {
        return;
      }

      final indexSpan = laterIndex - earlierIndex;
      if (indexSpan <= 0) return;
      final ratio = (target - earlierIndex) / indexSpan;
      var next = earlierOffset + (laterOffset - earlierOffset) * ratio;
      if ((next - current).abs() < 1) {
        final direction = target < first ? -1.0 : 1.0;
        next = current + direction * _scroll.position.viewportDimension * 0.7;
      }
      _scroll.jumpTo(next.clamp(0, _scroll.position.maxScrollExtent));
    }
  }

  GlobalKey _keyFor(ChatMessage message) =>
      _messageKeys.putIfAbsent(message.id, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final attachmentState = ref.watch(attachmentComposerControllerProvider);
    final persona = ref.watch(agentPersonaProvider);
    final spinner = ref.watch(appSettingsProvider).spinner;
    final chronologicalActivity = ref.watch(
      appSettingsProvider.select((settings) => settings.chronologicalActivity),
    );
    final boot = ref.watch(bootStateProvider);
    final online = boot.maybeWhen(
      data: (value) => value.online,
      orElse: () => false,
    );
    final canStop = boot.maybeWhen(
      data: (value) => value.capabilities.features.runStop,
      orElse: () => false,
    );
    final searchHits = _searching
        ? conversationSearchMatches(state.messages, _search.text)
        : const <int>[];
    final safeSearchCursor = searchHits.isEmpty
        ? 0
        : _searchCursor.clamp(0, searchHits.length - 1);
    final currentSearchIndex = searchHits.isEmpty
        ? null
        : searchHits[safeSearchCursor];
    final searchHitSet = searchHits.toSet();

    // Ao trocar de sessão, a thread agenda seu fim depois do layout. Dentro da
    // mesma conversa, quem subiu para reler recebe a contagem do que chegou sem
    // qualquer correção programática de posição.
    ref.listen(chatControllerProvider, (previous, next) {
      final historyHydrated =
          previous?.openingConversation == true &&
          !next.openingConversation &&
          next.conversationLoadFailure == null;
      if (previous?.sessionId != next.sessionId || historyHydrated) {
        _threadScroll.resetForConversation();
        return;
      }
      final arrived = next.messages.length - (previous?.messages.length ?? 0);
      _threadScroll.recordArrivals(arrived);
    });

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: PaperTexture()),
          SafeArea(
            child: Column(
              children: [
                _TopBar(
                  title: state.title,
                  subtitle:
                      '${shortModelLabel(state.modelId)} · ${online ? 'online' : 'offline'}',
                  onBack: () => context.pop(),
                  searching: _searching,
                  onSearch: _toggleSearch,
                  onSkills: () => context.push('/skills'),
                ),
                ClipRect(
                  child: AnimatedAlign(
                    duration: motionOf(context, HermesMotion.revelar),
                    curve: HermesMotion.curvaPadrao,
                    alignment: Alignment.topCenter,
                    heightFactor: _searching ? 1 : 0,
                    child: AnimatedOpacity(
                      // Mais curta que a altura de proposito: a barra termina
                      // de aparecer antes de terminar de descer, entao ela ja
                      // esta legivel enquanto assenta.
                      duration: motionOf(context, HermesMotion.estado),
                      opacity: _searching ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !_searching,
                        child: _ConversationSearchBar(
                          controller: _search,
                          focusNode: _searchFocus,
                          current: searchHits.isEmpty
                              ? 0
                              : safeSearchCursor + 1,
                          total: searchHits.length,
                          onChanged: _searchChanged,
                          onPrevious: () => _moveSearch(-1),
                          onNext: () => _moveSearch(1),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: state.openingConversation
                      ? _ConversationLoadingState(spinner: spinner)
                      : state.conversationLoadFailure != null
                      ? FailureState(
                          failure: state.conversationLoadFailure!,
                          keyPrefix: 'conversa',
                          onRetry: () => ref
                              .read(chatControllerProvider.notifier)
                              .retryOpenConversation(),
                        )
                      : state.messages.isEmpty &&
                            state.pendingApproval == null &&
                            state.pendingClarification == null
                      ? _EmptyState(spinner: spinner)
                      : ChatThreadView(
                          messageCount: state.messages.length,
                          scroll: _threadScroll,
                          onJumpToEnd: _resumeFollowing,
                          itemBuilder: (context, index) => _threadItem(
                            state.messages,
                            index,
                            spinner,
                            chronologicalActivity,
                            persona,
                            state.pendingApproval,
                            state.pendingClarification,
                            state.clarificationError,
                            searchHitSet,
                            currentSearchIndex,
                          ),
                        ),
                ),
                _Composer(
                  input: _input,
                  streaming: state.streaming,
                  conversationReady:
                      !state.openingConversation &&
                      state.conversationLoadFailure == null,
                  attachments: attachmentState.attachments,
                  attachmentBusy: attachmentState.busy,
                  attachmentError: attachmentState.error,
                  recording: attachmentState.recording,
                  recordingElapsed: _recordingElapsed,
                  // Com aprovação pendente o Hermes está parado esperando a
                  // decisão. Deixar cancelar aqui daria duas saídas para o mesmo
                  // impasse; a recusa no card é a saída explícita.
                  canStop:
                      canStop &&
                      state.pendingApproval == null &&
                      state.pendingClarification == null,
                  awaitingApproval:
                      state.pendingApproval != null ||
                      state.pendingClarification != null,
                  modelLabel: shortModelLabel(state.modelId),
                  promptHint: persona.composerHint,
                  onSend: _send,
                  onAttach: () => ref
                      .read(attachmentComposerControllerProvider.notifier)
                      .pickFile(),
                  onRemoveAttachment: (id) => ref
                      .read(attachmentComposerControllerProvider.notifier)
                      .remove(id),
                  onToggleRecording: _toggleRecording,
                  onCancelRecording: _cancelRecording,
                  onDismissAttachmentError: () => ref
                      .read(attachmentComposerControllerProvider.notifier)
                      .clearError(),
                  onStop: () =>
                      ref.read(chatControllerProvider.notifier).stop(),
                  onOpenModel: () => showModelSheet(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Responde a um pedido de aprovação e mostra a recusa, se houver.
  Future<void> _decidirAprovacao(ApprovalChoice choice) async {
    if (_approvalInFlight != null) return;
    setState(() => _approvalInFlight = choice);
    final erro = await ref
        .read(chatControllerProvider.notifier)
        .respondToApproval(choice);
    if (!mounted) return;
    setState(() => _approvalInFlight = null);
    if (erro == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
  }

  Future<void> _responderEsclarecimento(
    String questionId,
    Object answer,
  ) async {
    if (_clarificationInFlight != null) return;
    setState(() => _clarificationInFlight = questionId);
    final error = await ref
        .read(chatControllerProvider.notifier)
        .respondToClarification(answer, questionId: questionId);
    if (!mounted) return;
    setState(() => _clarificationInFlight = null);
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  /// Um item por mensagem, mais a cauda. O `ListView.builder` só constrói o que
  /// está perto da viewport, então um delta deixa de reconstruir a thread toda.
  Widget _threadItem(
    List<ChatMessage> messages,
    int index,
    String spinner,
    bool chronologicalActivity,
    AgentPersona persona,
    ApprovalRequest? approval,
    ClarifyRequest? clarification,
    String? clarificationError,
    Set<int> searchHits,
    int? currentSearchIndex,
  ) {
    // A cauda sai por inteiro enquanto o turno está ativo. Congelar seu primeiro
    // frame ainda deixava um glifo cinza solto no centro da área vazia, embora a
    // marca de atividade já estivesse junto da resposta.
    if (index == messages.length) {
      final responding = _brandIsWriting(messages);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // O pedido de aprovação fica **no fim da thread**, onde a leitura para
          // e onde a decisão precisa acontecer.
          ApprovalCardTransition(
            request: approval,
            respondingTo: _approvalInFlight,
            onChoice: _decidirAprovacao,
          ),
          ClarifyCardTransition(
            request: clarification,
            respondingTo: _clarificationInFlight,
            error: clarificationError,
            onAnswer: _responderEsclarecimento,
            persona: persona,
          ),
          if (!responding) _Tail(spinner: spinner),
        ],
      );
    }

    final message = messages[index];
    final bubble = switch (message) {
      UserMessage() => UserBubble(message, persona: persona),
      AssistantMessage() => AssistantBubble(
        message,
        spinner: spinner,
        chronologicalActivity: chronologicalActivity,
        persona: persona,
        onTimelineInteraction: _pauseFollowing,
      ),
    };
    final entry = Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: bubble,
    );

    // Só o turno que está chegando ganha entrada animada. Rodar o stagger em
    // histórico já lido reanimava tudo a cada reconstrução.
    final isLast = index == messages.length - 1;
    // `riseIn` do desenho: opacidade subindo junto com um deslocamento curto.
    final entrada = motionOf(context, HermesMotion.entrada);
    final animatedBody = isLast
        ? entry
              .animate()
              .fadeIn(duration: entrada, curve: HermesMotion.curvaSubida)
              .slideY(
                begin: 0.06,
                end: 0,
                duration: entrada,
                curve: HermesMotion.curvaSubida,
              )
        : entry;
    final t = HermesTokens.of(context);
    final matched = searchHits.contains(index);
    final current = currentSearchIndex == index;
    final body = AnimatedContainer(
      key: ValueKey('search-highlight-${message.id}'),
      duration: motionOf(context, HermesMotion.estado),
      curve: HermesMotion.curvaPadrao,
      decoration: BoxDecoration(
        color: current
            ? t.accent.withValues(alpha: 0.10)
            : matched
            ? t.accent.withValues(alpha: 0.035)
            : Colors.transparent,
        border: Border.all(
          color: current
              ? t.accent.withValues(alpha: 0.46)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: animatedBody,
    );

    // O fleuron marca troca de turno entre pessoa e agente. Andaime do runtime
    // não é turno de ninguém, então não abre seção. Ver A23.
    if (message is UserMessage && !message.scaffolding && index > 0) {
      return KeyedSubtree(
        key: _keyFor(message),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Fleuron(),
            ),
            body,
          ],
        ),
      );
    }
    return KeyedSubtree(key: _keyFor(message), child: body);
  }

  /// Verdadeiro quando o último turno está em andamento, ou seja, quando a marca
  /// já está sendo desenhada dentro da bolha, no ponto de escrita.
  bool _brandIsWriting(List<ChatMessage> messages) {
    final last = messages.isEmpty ? null : messages.last;
    return last is AssistantMessage &&
        (last.phase == ChatPhase.reasoning || last.phase == ChatPhase.writing);
  }
}

/// Marca no fim da thread quando nenhum turno está sendo escrito.
class _Tail extends StatelessWidget {
  const _Tail({required this.spinner});
  final String spinner;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: UnicodeSpinner(
          key: const ValueKey('conversation-tail-spinner'),
          name: spinner,
          size: 20,
          color: t.accentInk,
          glow: t.accent,
        ),
      ),
    );
  }
}

/// Cabeçalho da conversa. **Sem indicador de progresso**: desde o A13 o sinal de
/// atividade é a marca no ponto de escrita, e o botão de parar no composer marca
/// o estado global. Uma barra deslizando aqui era a terceira animação da tela.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.searching,
    required this.onSearch,
    required this.onSkills,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final bool searching;
  final VoidCallback onSearch;
  final VoidCallback onSkills;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onBack,
                      tooltip: 'Voltar',
                      icon: Icon(Icons.chevron_left, color: t.ink),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t
                            .serifIn(FontWeight.w500)
                            .copyWith(fontSize: 16.5, color: t.ink),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: t.mono.copyWith(
                          fontSize: 10,
                          color: t.faint,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('conversation-search-toggle'),
                        onPressed: onSearch,
                        tooltip: searching
                            ? 'Fechar busca'
                            : 'Buscar na conversa',
                        icon: Icon(
                          searching ? Icons.close : Icons.search,
                          size: 20,
                          color: searching ? t.accent : t.ink,
                        ),
                      ),
                      IconButton(
                        onPressed: onSkills,
                        tooltip: 'Skills',
                        icon: Icon(
                          Icons.auto_stories_outlined,
                          size: 20,
                          color: t.ink,
                        ),
                      ),
                    ],
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

/// Busca local do A25. O subtítulo mantém a limitação visível: o app não diz
/// "nenhum resultado" como se tivesse consultado trechos que não recebeu.
class _ConversationSearchBar extends StatelessWidget {
  const _ConversationSearchBar({
    required this.controller,
    required this.focusNode,
    required this.current,
    required this.total,
    required this.onChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int current;
  final int total;
  final ValueChanged<String> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final hasQuery = controller.text.trim().isNotEmpty;
    final status = switch ((hasQuery, total)) {
      (false, _) => 'SOMENTE MENSAGENS CARREGADAS',
      (true, 0) => 'NENHUMA NESTE TRECHO',
      (true, 1) => '1 MENSAGEM NESTE TRECHO',
      _ => '$total MENSAGENS NESTE TRECHO',
    };
    final canNavigate = total > 1;

    return Container(
      key: const ValueKey('conversation-search-bar'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 6, 4, 6),
        decoration: BoxDecoration(
          color: t.bg2,
          border: Border.all(color: t.line),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 16, color: t.faint),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    key: const ValueKey('conversation-search-field'),
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    onTapOutside: (_) => focusNode.unfocus(),
                    textInputAction: TextInputAction.search,
                    style: t.serif.copyWith(fontSize: 14, color: t.ink),
                    cursorColor: t.accent,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Buscar neste trecho',
                      hintStyle: t.mono.copyWith(
                        fontSize: 12.5,
                        color: t.faint,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.mono.copyWith(
                      fontSize: 8.5,
                      letterSpacing: 0.55,
                      color: total == 0 && hasQuery ? t.accentInk : t.faint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            SizedBox(
              width: 34,
              child: Text(
                '$current/$total',
                textAlign: TextAlign.center,
                style: t.mono.copyWith(fontSize: 10, color: t.dim),
              ),
            ),
            IconButton(
              key: const ValueKey('search-previous'),
              onPressed: canNavigate ? onPrevious : null,
              tooltip: 'Resultado anterior',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.keyboard_arrow_up, size: 20, color: t.dim),
            ),
            IconButton(
              key: const ValueKey('search-next'),
              onPressed: canNavigate ? onNext : null,
              tooltip: 'Próximo resultado',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.keyboard_arrow_down, size: 20, color: t.dim),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.input,
    required this.streaming,
    required this.conversationReady,
    required this.canStop,
    required this.attachments,
    required this.attachmentBusy,
    required this.recording,
    required this.recordingElapsed,
    this.awaitingApproval = false,
    this.attachmentError,
    required this.modelLabel,
    required this.promptHint,
    required this.onSend,
    required this.onStop,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onToggleRecording,
    required this.onCancelRecording,
    required this.onDismissAttachmentError,
    required this.onOpenModel,
  });

  final TextEditingController input;
  final bool streaming;
  final bool conversationReady;
  final bool canStop;
  final List<ComposerAttachment> attachments;
  final bool attachmentBusy;
  final bool recording;
  final Duration recordingElapsed;

  /// O Hermes está parado esperando decisão de aprovação.
  final bool awaitingApproval;
  final String? attachmentError;
  final String modelLabel;
  final String promptHint;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final VoidCallback onAttach;
  final ValueChanged<String> onRemoveAttachment;
  final VoidCallback onToggleRecording;
  final VoidCallback onCancelRecording;
  final VoidCallback onDismissAttachmentError;
  final VoidCallback onOpenModel;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final hasText = input.text.trim().isNotEmpty;
    final hasAttachments = attachments.isNotEmpty;
    final canSend =
        conversationReady &&
        (hasText || hasAttachments) &&
        !streaming &&
        !awaitingApproval &&
        !attachmentBusy &&
        !recording;
    final canCompose =
        conversationReady && !streaming && !awaitingApproval && !attachmentBusy;

    final podeAnexar = canCompose && !recording;
    // O microfone só existe quando não há nada para enviar: com texto ou anexo,
    // a ação da vez é enviar, e duas ofertas no mesmo canto disputam o dedo.
    final mostrarMicrofone =
        conversationReady &&
        !streaming &&
        !hasText &&
        !hasAttachments &&
        !recording;

    return Container(
      // Sem folga no topo: a faixa das pastilhas já carrega a sua, por dentro
      // do alvo de toque de 48. Ver [_alvoDeToque].
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _alvoDeToque,
            child: Row(
              children: [
                HermesChip(
                  icon: Icons.smart_toy_outlined,
                  label: modelLabel,
                  selected: true,
                  minTapHeight: _alvoDeToque,
                  onTap: onOpenModel,
                ),
                const SizedBox(width: 7),
                // A32: a máquina que roda o agente fica a um toque de onde se
                // fala com ele, porque as duas coisas se misturam no uso.
                HermesChip(
                  key: const ValueKey('chip-maquina'),
                  icon: Icons.terminal,
                  label: 'Máquina',
                  minTapHeight: _alvoDeToque,
                  onTap: () => context.push('/maquina'),
                ),
              ],
            ),
          ),
          // A folga acima de cada bloco opcional é a sobra do alvo de toque da
          // faixa anterior; a de baixo é explícita. Assim a barra tem o mesmo
          // respiro com e sem anexo, gravação ou aviso.
          if (attachments.isNotEmpty) ...[
            _ComposerAttachmentStrip(
              attachments: attachments,
              busy: attachmentBusy,
              onRemove: onRemoveAttachment,
            ),
            const SizedBox(height: _folgaEntreFaixas),
          ],
          if (recording) ...[
            _RecordingBar(
              elapsed: recordingElapsed,
              onStop: onToggleRecording,
              onCancel: onCancelRecording,
            ),
            const SizedBox(height: _folgaEntreFaixas),
          ],
          if (attachmentError != null) ...[
            _ComposerError(
              message: attachmentError!,
              onDismiss: onDismissAttachmentError,
            ),
            const SizedBox(height: _folgaEntreFaixas),
          ],
          _ComposerSurface(
            key: const ValueKey('composer-field'),
            child: Row(
              // `align-items:flex-end` do desenho. Sem isto, um campo de cinco
              // linhas deixa os botões boiando no meio do bloco de texto, longe
              // da linha que está sendo escrita.
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ComposerButton(
                  key: const ValueKey('composer-attach'),
                  icon: Icons.add_rounded,
                  tooltip: 'Anexar arquivo',
                  foreground: podeAnexar ? t.dim : t.faint,
                  onTap: podeAnexar ? onAttach : null,
                ),
                // Sem folga externa: o campo do Material já se dá um mínimo de
                // 48, o mesmo alvo de toque das caixas ao lado, então ele
                // centra sozinho na linha. Medido: somar folga aqui inchava a
                // linha para 69px e deixava o texto 13px acima dos botões.
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: t.serif.copyWith(fontSize: 16, color: t.ink),
                    cursorColor: t.accent,
                    // Com aprovação pendente a run está bloqueada: digitar
                    // outra mensagem só criaria a ilusão de que ela seria
                    // atendida.
                    enabled:
                        conversationReady &&
                        !awaitingApproval &&
                        !attachmentBusy &&
                        !recording,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      // A folga de baixo é o que decide onde a linha sendo
                      // escrita cai, porque um campo colapsado alinha o
                      // conteúdo pela base.
                      //
                      // **Não meça isto pelo centro da caixa do texto.** A
                      // caixa tem a altura da linha e inclui o espaço do
                      // descendente, que as letras quase não ocupam, então a
                      // tinta fica uns 4px acima do centro dela. Medindo o
                      // centro da caixa cheguei a 12 aqui, e no aparelho o
                      // texto saiu visivelmente alto; foi o usuário quem
                      // apontou.
                      //
                      // Com 6, medido na tinta da captura a 3x: o `+` centra em
                      // 2797, o microfone em 2795,5, o enviar em 2797, e o
                      // texto em 2803. Dois pixels lógicos de diferença, que é
                      // o mesmo que alinhado.
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      hintText: !conversationReady
                          ? 'A conversa ainda não está disponível…'
                          : awaitingApproval
                          ? 'Aguardando sua decisão acima…'
                          : recording
                          ? 'Gravando mensagem de voz…'
                          : attachmentBusy
                          ? 'Preparando anexos…'
                          : promptHint,
                      hintStyle: t.serif.copyWith(fontSize: 16, color: t.faint),
                    ),
                  ),
                ),
                // A largura do microfone entra e sai animada, senão o botão de
                // enviar salta de lugar na primeira letra digitada.
                AnimatedSize(
                  duration: motionOf(context, HermesMotion.estado),
                  curve: HermesMotion.curvaPadrao,
                  alignment: Alignment.centerRight,
                  child: mostrarMicrofone
                      ? _ComposerButton(
                          key: const ValueKey('composer-record'),
                          icon: Icons.mic_none_rounded,
                          tooltip: 'Gravar mensagem de voz',
                          foreground: canCompose ? t.dim : t.faint,
                          onTap: canCompose ? onToggleRecording : null,
                        )
                      : const SizedBox(height: _alvoDeToque),
                ),
                _SendButton(
                  key: const ValueKey('composer-send'),
                  streaming: streaming,
                  awaitingApproval: awaitingApproval,
                  enabled: canSend || (streaming && canStop),
                  onTap: streaming
                      ? (canStop ? onStop : null)
                      : (canSend ? onSend : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma faixa da barra de mensagem.
///
/// Campo, gravação e aviso são a mesma superfície em estados diferentes, então
/// têm a mesma silhueta, a mesma folga e a mesma grade. O primeiro e o último
/// lugar da linha são sempre caixas de 48, e é isso que faz o `+`, o ponto de
/// gravação e o ícone de aviso caírem na **mesma coluna**, e o enviar, o parar
/// e o fechar caírem na outra.
///
/// Antes cada faixa tinha o seu: o campo era um retângulo de raio 22 com folga
/// `6,2,2,2`, a gravação um de raio 12 com folga `12,2,2,2`, e o aviso não era
/// superfície nenhuma. Empilhadas, não pareciam da mesma família.
class _ComposerSurface extends StatelessWidget {
  const _ComposerSurface({super.key, required this.child, this.borderColor});

  final Widget child;

  /// Só o aviso muda: a borda vira âmbar-tinta para dizer que algo falhou.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Container(
      // 2 de folga em volta de caixas de 48 devolve exatamente o `padding:8px`
      // do desenho em torno de uma marca de 36, e a faixa fica com os mesmos
      // 52px de altura. A esquerda é maior porque o desenho também a faz maior
      // (`padding:8px 8px 8px 15px`), já que ali não há círculo para ocupar a
      // folga.
      padding: const EdgeInsets.fromLTRB(6, 2, 2, 2),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: borderColor ?? t.line),
        borderRadius: HermesRadius.todos(HermesRadius.capsula),
      ),
      child: child,
    );
  }
}

/// O primeiro lugar de uma faixa, quando não é um botão: mantém a coluna da
/// esquerda alinhada mesmo quando o que está ali é um ponto ou um aviso.
class _ComposerSlot extends StatelessWidget {
  const _ComposerSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _alvoDeToque,
    height: _alvoDeToque,
    child: Center(child: child),
  );
}

/// A grade de toque da barra de mensagem.
///
/// 48 é o mínimo do Android e cobre os 44 do iOS. **Toda** coisa tocável aqui
/// tem esta caixa: pastilha, anexar, microfone, enviar, parar gravação, fechar
/// aviso e remover anexo. Antes eram cinco geometrias diferentes no mesmo
/// canto da tela, nenhuma delas atingindo o mínimo, e era isso que fazia a
/// barra parecer montada aos pedaços.
const double _alvoDeToque = 48;

/// A marca desenhada dentro do alvo: o círculo de 36 do desenho
/// (`sendBtnStyle`). A caixa maior é folga de toque, não peso visual.
const double _marcaDeBotao = 36;

/// A folga entre duas faixas empilhadas da barra.
const double _folgaEntreFaixas = 9;

/// Um controle da barra de mensagem.
///
/// Regra de hierarquia, e é dela que sai a consistência: **só a ação primária
/// usa círculo preenchido.** O desenho tem exatamente um círculo no composer, o
/// de enviar. Anexar e gravar são secundárias e ficam como glifo nu.
///
/// Antes o microfone usava o mesmo círculo com borda que o enviar desabilitado,
/// então a barra vazia mostrava dois círculos idênticos lado a lado e nada
/// dizia qual era a ação da vez.
class _ComposerButton extends StatelessWidget {
  const _ComposerButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.background,
    this.foreground,
    this.border,
    this.glow,
    this.iconSize,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  /// Nulo desenha o glifo nu, sem círculo: é o estado das ações secundárias.
  final Color? background;
  final Color? foreground;
  final Color? border;

  /// A cor do brilho sob o círculo aceso. `sendBtnStyle` do desenho:
  /// `box-shadow:0 4px 16px -4px accent 55%`, com um fio de luz interno no
  /// topo. É o único momento de profundidade da barra, e é o que marca a ação
  /// primária sem precisar de tamanho diferente.
  final Color? glow;

  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final preenchido = background != null;
    return TapScale(
      onTap: onTap,
      tooltip: tooltip,
      child: SizedBox(
        width: _alvoDeToque,
        height: _alvoDeToque,
        child: Center(
          child: AnimatedContainer(
            duration: motionOf(context, HermesMotion.superficie),
            curve: HermesMotion.curvaPadrao,
            width: _marcaDeBotao,
            height: _marcaDeBotao,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background,
              border: border == null ? null : Border.all(color: border!),
              boxShadow: glow == null
                  ? null
                  : [
                      BoxShadow(
                        color: glow!.withValues(alpha: 0.55),
                        offset: const Offset(0, 4),
                        blurRadius: 16,
                        spreadRadius: -4,
                      ),
                    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // O `inset 0 1px 0 rgba(255,255,255,.3)` do desenho. O Flutter
                // não tem sombra interna, então o fio de luz vem de um degradê
                // circular do próprio tamanho da marca.
                if (glow != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.55],
                      ),
                    ),
                    child: const SizedBox(
                      width: _marcaDeBotao,
                      height: _marcaDeBotao,
                    ),
                  ),
                Icon(
                  icon,
                  // Glifo nu sai 1px maior que glifo sobre disco cheio, que é a
                  // compensação óptica do próprio desenho (19 no `+`, 18 no
                  // enviar): dentro de um disco, o mesmo glifo lê maior.
                  size: iconSize ?? (preenchido ? 18 : 19),
                  color: foreground ?? (onTap == null ? t.faint : t.dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComposerAttachmentStrip extends StatelessWidget {
  const _ComposerAttachmentStrip({
    required this.attachments,
    required this.busy,
    required this.onRemove,
  });

  final List<ComposerAttachment> attachments;
  final bool busy;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // A altura de uma faixa da barra, para a tira de anexos não destoar das
      // outras linhas empilhadas.
      height: _alvoDeToque + 4,
      child: ListView.separated(
        key: const ValueKey('composer-attachments'),
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          return _ComposerAttachmentChip(
            attachment: attachment,
            onRemove: busy ? null : () => onRemove(attachment.id),
          );
        },
      ),
    );
  }
}

class _ComposerAttachmentChip extends StatelessWidget {
  const _ComposerAttachmentChip({
    required this.attachment,
    required this.onRemove,
  });

  final ComposerAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final uploading = attachment.status == ComposerAttachmentStatus.uploading;
    final failed = attachment.status == ComposerAttachmentStatus.failed;
    return AnimatedContainer(
      duration: motionOf(context, HermesMotion.estado),
      curve: HermesMotion.curvaPadrao,
      constraints: const BoxConstraints(maxWidth: 238),
      // Sem folga à direita: a caixa de 48 do botão de remover já a carrega.
      padding: const EdgeInsets.fromLTRB(11, 0, 0, 0),
      decoration: BoxDecoration(
        color: t.bg2,
        border: Border.all(color: failed ? t.accentInk : t.line),
        borderRadius: HermesRadius.todos(HermesRadius.capsula),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (uploading)
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: t.accent,
              ),
            )
          else
            Icon(
              attachment.kind == ComposerAttachmentKind.audio
                  ? Icons.graphic_eq_rounded
                  : Icons.insert_drive_file_outlined,
              size: 16,
              color: failed ? t.accentInk : t.accent,
            ),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.mono.copyWith(
                    fontSize: 11.5,
                    height: 1.15,
                    color: t.ink,
                  ),
                ),
                Text(
                  failed
                      ? 'FALHA NO ENVIO'
                      : uploading
                      ? 'ENVIANDO…'
                      : attachmentSizeLabel(attachment.bytes.length),
                  maxLines: 1,
                  style: t.mono.copyWith(
                    fontSize: 8.5,
                    height: 1.15,
                    letterSpacing: 0.45,
                    color: failed ? t.accentInk : t.faint,
                  ),
                ),
              ],
            ),
          ),
          _ComposerButton(
            icon: Icons.close_rounded,
            tooltip: 'Remover ${attachment.name}',
            foreground: t.faint,
            iconSize: 15,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.elapsed,
    required this.onStop,
    required this.onCancel,
  });

  final Duration elapsed;
  final VoidCallback onStop;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return _ComposerSurface(
      key: const ValueKey('composer-recording'),
      child: Row(
        children: [
          // Na mesma coluna do `+` do campo, logo abaixo.
          _ComposerSlot(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: t.accentInk,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Text(
            'GRAVANDO  $minutes:$seconds',
            style: t.mono.copyWith(
              fontSize: 10,
              letterSpacing: 0.75,
              color: t.ink,
            ),
          ),
          const Spacer(),
          _ComposerTextAction(label: 'Cancelar', onTap: onCancel),
          _ComposerButton(
            icon: Icons.stop_rounded,
            tooltip: 'Concluir gravação',
            background: t.accentInk,
            foreground: t.bg,
            glow: t.accentInk,
            onTap: onStop,
          ),
        ],
      ),
    );
  }
}

class _ComposerError extends StatelessWidget {
  const _ComposerError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return _ComposerSurface(
      borderColor: t.accentInk,
      child: Row(
        children: [
          _ComposerSlot(
            child: Icon(Icons.error_outline, size: 19, color: t.accentInk),
          ),
          Expanded(
            child: Text(
              message,
              style: t.serif.copyWith(fontSize: 13, color: t.accentInk),
            ),
          ),
          _ComposerButton(
            icon: Icons.close_rounded,
            tooltip: 'Fechar aviso',
            foreground: t.faint,
            iconSize: 19,
            onTap: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// A ação primária da barra, e o único círculo preenchido dela.
///
/// Três papéis no mesmo lugar, porque são o mesmo gesto em momentos
/// diferentes: enviar, parar o que está sendo respondido, e o cadeado de quando
/// há aprovação pendente. Mostrar "parar" durante a aprovação prometeria uma
/// saída que este botão não dá, porque a saída explícita é recusar no card.
class _SendButton extends StatelessWidget {
  const _SendButton({
    super.key,
    required this.streaming,
    required this.enabled,
    required this.onTap,
    this.awaitingApproval = false,
  });
  final bool streaming;
  final bool enabled;
  final bool awaitingApproval;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    final aceso = enabled && !awaitingApproval;
    final parando = streaming && !awaitingApproval;
    final fundo = parando ? t.accentInk : (aceso ? t.accent : t.surface);
    return _ComposerButton(
      icon: awaitingApproval
          ? Icons.lock_outline
          : (streaming ? Icons.stop_rounded : Icons.arrow_upward_rounded),
      tooltip: awaitingApproval
          ? 'Aguardando sua decisão'
          : (streaming ? 'Parar a resposta' : 'Enviar mensagem'),
      background: fundo,
      foreground: (aceso || parando) ? t.bg : t.faint,
      border: (aceso || parando) ? null : t.line,
      // O brilho só acende quando o botão de fato faz alguma coisa: é o sinal
      // de que a ação está armada, e não decoração permanente.
      glow: (aceso || parando) ? fundo : null,
      onTap: awaitingApproval ? null : onTap,
    );
  }
}

/// Ação em texto da barra, para quando um glifo não diria o que faz.
///
/// Existe para "Cancelar" na gravação, que antes era um `TextButton` do
/// Material: trazia densidade, altura e respingo de outra família visual, ao
/// lado de um botão que não tem nada disso.
class _ComposerTextAction extends StatelessWidget {
  const _ComposerTextAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return TapScale(
      onTap: onTap,
      semanticsLabel: label,
      child: SizedBox(
        height: _alvoDeToque,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: t.mono.copyWith(fontSize: 10, color: t.dim),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.spinner});
  final String spinner;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Center(
      child:
          Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UnicodeSpinner(
                      name: spinner,
                      size: 30,
                      color: t.accentInk,
                      glow: t.accent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'HERMES AGENT',
                      style: t.mono.copyWith(
                        fontSize: 10.5,
                        letterSpacing: 2.2,
                        color: t.faint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No que estamos trabalhando?',
                      textAlign: TextAlign.center,
                      style: t
                          .serifIn(FontWeight.w500, italic: true)
                          .copyWith(fontSize: 27, height: 1.25, color: t.ink),
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: motionOf(context, HermesMotion.entrada))
              .slideY(
                begin: 0.08,
                end: 0,
                duration: motionOf(context, HermesMotion.entrada),
                curve: HermesMotion.curvaSubida,
              ),
    );
  }
}

class _ConversationLoadingState extends StatelessWidget {
  const _ConversationLoadingState({required this.spinner});

  final String spinner;

  @override
  Widget build(BuildContext context) {
    final t = HermesTokens.of(context);
    return Semantics(
      liveRegion: true,
      label: 'Abrindo conversa',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UnicodeSpinner(
              key: const ValueKey('conversation-opening-spinner'),
              name: spinner,
              size: 25,
              color: t.accentInk,
              glow: t.accent,
            ),
            const SizedBox(height: 12),
            Text(
              'ABRINDO CONVERSA',
              style: t.mono.copyWith(
                fontSize: 10,
                letterSpacing: 1.8,
                color: t.faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
