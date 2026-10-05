import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/diagnostics/turn_capture.dart';
import '../../data/config/active_run_store.dart';
import '../../data/gateway_repository_provider.dart';
import '../../data/hermes_repository_provider.dart';
import '../../domain/models/approval_request.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/conversation_timeline.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/model_lock.dart';
import '../../domain/models/model_options.dart';
import '../../domain/models/model_selection.dart';
import '../../domain/models/reasoning_config.dart';
import '../../domain/models/run.dart';
import '../../domain/models/run_event.dart';
import '../../domain/models/session_message.dart';
import '../../domain/models/tool_timeline.dart';
import '../../domain/models/turn_activity.dart';
import '../../domain/repositories/hermes_repository.dart';
import '../../domain/repositories/gateway_repository.dart';
import 'boot_provider.dart';
import 'active_conversations_provider.dart';
import 'chat_drafts_provider.dart';
import 'chat_state.dart';
import 'conversations_provider.dart';
import 'launch_provider.dart';
import 'inventory_provider.dart';
import '../settings/settings_provider.dart';

export 'active_conversations_provider.dart'
    show activeConversationIdsProvider, activeRunStoreProvider;

part 'chat_controller.g.dart';

/// Pequena espera entre snapshots após o encerramento inesperado do SSE.
/// Pode ser sobrescrita nos testes para não introduzir espera real.
final runReconciliationDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 250),
);

enum _GatewayTurnStart { unavailable, submitted, notSubmitted }

/// Coordena sessão, histórico persistido e streaming da Runs API.
@Riverpod(keepAlive: true)
class ChatController extends _$ChatController {
  StreamSubscription<RunEvent>? _sub;
  GatewayLiveTurn? _gatewayTurn;
  final Stopwatch _reasonWatch = Stopwatch();
  Future<void> _activeRunWrites = Future<void>.value();
  int _epoch = 0;
  int _turnEventSerial = 0;
  int _listenerGeneration = 0;
  bool _liveUpdatesVisible = true;

  @override
  ChatState build() {
    ref.onDispose(() {
      unawaited(_sub?.cancel());
      unawaited(_gatewayTurn?.close());
    });
    final settings = ref.read(appSettingsProvider);
    return ChatState(
      reasoning: ReasoningConfig(showActivity: settings.showActivity),
      instructions: settings.instructions,
    );
  }

  HermesRepository get _repo => ref.read(hermesRepositoryProvider);
  ActiveRunStore get _activeRuns => ref.read(activeRunStoreProvider);

  /// Mantém conexões ao vivo somente enquanto a conversa pode ser vista.
  ///
  /// A execução pertence ao servidor e nunca é interrompida aqui. Ao ocultar a
  /// rota ou o app, apenas listeners locais são soltos. Ao voltar, histórico e
  /// snapshot autoritativos decidem se ainda há algo para reconectar.
  Future<void> setLiveUpdatesVisible(bool visible) async {
    if (_liveUpdatesVisible == visible) return;
    _liveUpdatesVisible = visible;
    final generation = ++_listenerGeneration;

    if (!visible) {
      final subscription = _sub;
      final turn = _gatewayTurn;
      _sub = null;
      _gatewayTurn = null;
      await subscription?.cancel();
      await turn?.close();
      return;
    }

    await _resumeVisibleConversation(generation);
  }

  Future<void> _resumeVisibleConversation(int generation) async {
    final sessionId = state.sessionId;
    final epoch = _epoch;
    if (sessionId == null || state.openingConversation) return;

    final ActiveRunRecord? active;
    try {
      active = await _activeRuns.read(sessionId);
    } catch (_) {
      return;
    }
    if (active == null || !_canListen(epoch, generation)) return;

    try {
      final persisted = await _repo.conversationMessages(sessionId);
      if (!_canListen(epoch, generation)) return;
      state = state.copyWith(
        messages: _timelineComTurnoEmCurso(
          persisted,
          assistantMessageId: active.assistantMessageId,
          model: state.modelId,
        ),
      );
    } catch (_) {
      // O registro e o snapshot ainda permitem retomar uma run quando o
      // histórico estiver temporariamente indisponível.
    }
    if (!_canListen(epoch, generation)) return;
    await _resumeActiveRun(sessionId, epoch, listenerGeneration: generation);
  }

  bool _canListen(int epoch, [int? generation]) =>
      _liveUpdatesVisible &&
      epoch == _epoch &&
      (generation == null || generation == _listenerGeneration);

  ModelLock? get _stateModelLock {
    final model = state.modelId.trim();
    if (model.isEmpty) return null;
    return ModelLock(model: model, provider: state.modelProvider);
  }

  String? _usableModelId(String? candidate) {
    final model = candidate?.trim();
    if (model == null || model.isEmpty || isCompatibilityModelAlias(model)) {
      final current = state.modelId.trim();
      return current.isEmpty || isCompatibilityModelAlias(current)
          ? null
          : current;
    }
    return model;
  }

  /// Resolve o LLM concreto sem usar `hermes-agent` como modelo.
  ///
  /// O par efetivo de `/api/model/options` tem precedência para conversas novas
  /// e para o reparo pontual de sessões legadas. Se o inventário falhar, uma
  /// escolha concreta já gravada é preservada; um alias nunca vira fallback.
  Future<ModelLock?> _resolvedModelLock({ModelLock? preferred}) async {
    final selected = preferred ?? _stateModelLock;
    final concrete = resolveModelLock(
      options: const ModelOptions(),
      preferred: selected,
    );
    if (concrete != null) return concrete;

    var options = const ModelOptions();
    try {
      options = (await ref.read(modelInventoryProvider.future)).options;
    } catch (_) {
      // O catálogo enriquecido pode estar indisponível. Abaixo ainda
      // preservamos um modelo concreto ou usamos `/v1/models` sem alias.
    }

    final fromOptions = resolveModelLock(options: options, preferred: selected);
    if (fromOptions != null) return fromOptions;

    try {
      final boot = await ref.read(bootStateProvider.future);
      return resolveModelLock(
        options: options,
        preferred: selected,
        advertised: boot.models,
      );
    } catch (_) {
      return resolveModelLock(options: options, preferred: selected);
    }
  }

  /// Cria uma sessão real no Hermes antes de abrir uma conversa nova.
  Future<void> newChat() async {
    final epoch = ++_epoch;
    await _sub?.cancel();
    await _closeGatewayTurn();
    _finishFlagsOnly();
    final modelLock = await _resolvedModelLock();
    if (epoch != _epoch) return;
    final conversation = await _repo.createConversation(
      model: modelLock?.model,
      provider: modelLock?.provider,
    );
    if (epoch != _epoch) return;
    final returned = ModelLock(
      model: conversation.model ?? '',
      provider: conversation.provider,
    );
    final effective =
        resolveModelLock(options: const ModelOptions(), preferred: returned) ??
        modelLock;
    state = ChatState(
      modelId: effective?.model ?? '',
      modelProvider: effective?.provider,
      reasoning: state.reasoning,
      instructions: state.instructions,
      sessionId: conversation.id,
    );
    _rememberLastConversation(conversation.id, conversation.title);
    ref.invalidate(conversationFeedProvider);
  }

  /// Guarda onde a pessoa está para o próximo launch abrir aqui (A64).
  ///
  /// Sem `await` de propósito: lembrar o lugar é conveniência, e falhar em
  /// gravar não pode atrasar nem derrubar a abertura da conversa.
  void _rememberLastConversation(String sessionId, String title) {
    unawaited(
      ref
          .read(lastConversationStoreProvider)
          .save(sessionId, title)
          .catchError((Object _) {}),
    );
  }

  /// Esquece o lugar quando o servidor diz que ele não existe mais.
  ///
  /// Só em `404`. Rede fora do ar não pode apagar a lembrança: a próxima
  /// abertura tenta de novo, e é isso que separa conversa apagada de servidor
  /// inalcançável sem gastar uma consulta na abertura de todo dia.
  void _forgetLastConversationIfGone(HermesFailure failure) {
    if (failure.kind != HermesFailureKind.naoEncontrado) return;
    unawaited(
      ref.read(lastConversationStoreProvider).clear().catchError((Object _) {}),
    );
  }

  /// Prepara a rota imediatamente e hidrata o histórico já dentro do chat.
  Future<void> openConversation(Conversation conversation) {
    final epoch = ++_epoch;
    _finishFlagsOnly();
    final persistedLock = ModelLock(
      model: conversation.model ?? '',
      provider: conversation.provider,
    );
    final immediatelyUsable = resolveModelLock(
      options: const ModelOptions(),
      preferred: persistedLock,
    );
    state = ChatState(
      title: conversation.title,
      sessionId: conversation.id,
      modelId: immediatelyUsable?.model ?? '',
      modelProvider: immediatelyUsable?.provider,
      reasoning: state.reasoning,
      instructions: state.instructions,
      openingConversation: true,
    );
    _rememberLastConversation(conversation.id, conversation.title);
    return _hydrateConversation(
      conversation.id,
      persistedLock,
      epoch,
      repairAlias: isCompatibilityModelAlias(persistedLock.model),
    );
  }

  Future<void> retryOpenConversation() async {
    final sessionId = state.sessionId;
    if (sessionId == null || state.openingConversation) return;
    final epoch = ++_epoch;
    state = state.copyWith(
      messages: const <ChatMessage>[],
      streaming: false,
      runId: null,
      openingConversation: true,
      conversationLoadFailure: null,
      pendingApproval: null,
      approvalError: null,
      pendingClarification: null,
      clarificationError: null,
    );
    await _hydrateConversation(sessionId, _stateModelLock, epoch);
  }

  Future<void> _hydrateConversation(
    String sessionId,
    ModelLock? persistedLock,
    int epoch, {
    bool repairAlias = false,
  }) async {
    try {
      await _sub?.cancel();
      await _closeGatewayTurn();
      var effective = await _resolvedModelLock(preferred: persistedLock);
      if (repairAlias && effective != null) {
        try {
          effective = await _repo.lockConversationModel(sessionId, effective);
        } catch (_) {
          // O reparo é individual e explícito, mas o override concreto ainda é
          // mais seguro que reenviar o alias que já produziu HTTP 400.
        }
      }
      if (epoch != _epoch) return;
      state = state.copyWith(
        modelId: effective?.model ?? '',
        modelProvider: effective?.provider,
      );
      var persisted = await _repo.conversationMessages(sessionId);
      if (epoch != _epoch) return;

      // A Runs API e o Dashboard TUI não têm a mesma riqueza de histórico.
      // Depois que um turno TUI termina, o registro local de run é apagado; no
      // cold start, portanto, ninguém chamava mais `session.history` e a tela
      // nascia vazia. Lemos o registro antes para não disputar a retomada de um
      // turno ainda ativo e usamos o Dashboard como fonte autoritativa quando
      // ele está pareado. HTTP continua sendo o fallback seguro.
      ActiveRunRecord? active;
      var activeRunRead = false;
      try {
        active = await _activeRuns.read(sessionId);
        activeRunRead = true;
      } catch (_) {
        // Uma falha no armazenamento local não invalida o histórico remoto.
      }
      if (epoch != _epoch) return;
      if (active == null) {
        final dashboardHistory = await _dashboardConversationHistory(sessionId);
        if (epoch != _epoch) return;
        if (dashboardHistory.isNotEmpty) persisted = dashboardHistory;
      }

      state = state.copyWith(
        messages: conversationTimeline(persisted, model: effective?.model),
        openingConversation: false,
        conversationLoadFailure: null,
      );
      if (active != null) {
        await _resumeActiveRecord(active, epoch);
      } else if (!activeRunRead) {
        // Se a leitura local falhou, preserva a tentativa original: ela pode
        // ter sido apenas transitória e ainda há uma run para reconectar.
        await _resumeActiveRun(sessionId, epoch);
      }
    } catch (error) {
      if (epoch != _epoch) return;
      final failure = hermesFailureFrom(error);
      _forgetLastConversationIfGone(failure);
      state = state.copyWith(
        openingConversation: false,
        conversationLoadFailure: failure,
      );
    }
  }

  /// Envia uma mensagem pelo gateway TUI quando ele já está pareado; Runs
  /// continua como fallback compatível até o transporte novo ser validado.
  Future<bool> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty ||
        state.streaming ||
        state.openingConversation ||
        state.conversationLoadFailure != null ||
        state.sessionId == null) {
      return false;
    }

    final now = _hhmm();
    final userId = 'u${_uid()}';
    final asstId = 'a${_uid()}';
    final showActivity = state.reasoning.showActivity;
    final history = _history(state.messages);
    final title = state.messages.isEmpty ? _titleFrom(text) : state.title;
    final sessionId = state.sessionId!;
    final epoch = _epoch;

    state = state.copyWith(
      title: title,
      streaming: true,
      messages: [
        ...state.messages,
        ChatMessage.user(id: userId, text: text, time: now),
        ChatMessage.assistant(
          id: asstId,
          phase: showActivity ? ChatPhase.reasoning : ChatPhase.writing,
          time: now,
          model: state.modelId,
        ),
      ],
    );
    ref.read(activeConversationIdsProvider.notifier).markActive(sessionId);

    _reasonWatch
      ..reset()
      ..start();
    // Antes de abrir qualquer transporte: o `gateway.ready` e o `session.resume`
    // fazem parte do turno que a captura precisa explicar.
    turnCapture.beginTurn(sessionId: sessionId, origin: 'envio');

    try {
      if (history.isEmpty) unawaited(_updateTitle(sessionId, title));
      final gatewayStart = await _startGatewayTurn(
        text: text,
        sessionId: sessionId,
        assistantMessageId: asstId,
        epoch: epoch,
      );
      if (gatewayStart == _GatewayTurnStart.submitted) {
        ref.read(chatDraftsProvider.notifier).clear(sessionId);
        return true;
      }
      if (gatewayStart == _GatewayTurnStart.notSubmitted) {
        return false;
      }
      if (epoch != _epoch) {
        ref
            .read(activeConversationIdsProvider.notifier)
            .markInactive(sessionId);
        return false;
      }

      final run = await _repo.createRun(
        input: text,
        sessionId: sessionId,
        instructions: state.instructions.trim().isEmpty
            ? null
            : state.instructions,
        model: state.modelId.trim().isEmpty ? null : state.modelId,
        conversationHistory: history,
      );
      final remembering = _rememberActiveRun(
        sessionId: sessionId,
        runId: run.runId,
        model: run.model,
        assistantMessageId: asstId,
        startedAt: DateTime.now(),
      );
      if (epoch != _epoch) {
        await remembering;
        ref.read(chatDraftsProvider.notifier).clear(sessionId);
        return true;
      }
      state = state.copyWith(runId: run.runId);
      _patch(asstId, (message) => message.copyWith(runId: run.runId));
      _listenToRun(asstId, run.runId, epoch);
      await remembering;
      ref.read(chatDraftsProvider.notifier).clear(sessionId);
      return true;
    } catch (error) {
      if (epoch == _epoch) {
        _fail(asstId, _legivel(error), epoch: epoch, clearActiveRun: true);
      } else {
        ref
            .read(activeConversationIdsProvider.notifier)
            .markInactive(sessionId);
      }
      return false;
    }
  }

  /// Pede cancelamento ao endpoint real da Runs API.
  Future<void> stop() async {
    final id = state.runId;
    if (id == null || !state.streaming) return;
    try {
      final turn = _gatewayTurn;
      if (turn != null) {
        await turn.interrupt();
      } else {
        await _repo.stopRun(id);
      }
    } catch (error) {
      _failCurrentAssistant(_legivel(error));
    }
  }

  /// Escolhe o modelo da conversa **no servidor**, não só no estado local.
  ///
  /// Antes isto só mudava o chip: a run seguinte mandava o id e o gateway
  /// resolvia como quisesse. Agora grava a trava de sessão, então a escolha
  /// sobrevive ao app e vale para a conversa inteira.
  ///
  /// Devolve `null` quando deu certo, ou a mensagem da recusa. O caso que importa
  /// é o `409`: o Hermes prefere recusar a trocar em silêncio para o modelo
  /// global, e mentir para o usuário aqui seria pior que a recusa.
  Future<String?> setModel(String id, {String? provider}) async {
    if (isCompatibilityModelAlias(id)) {
      return 'hermes-agent identifica o agente, não um modelo LLM. Escolha '
          'um modelo anunciado pelo provider.';
    }
    final pedido = ModelLock(model: id, provider: provider);
    final sessionId = state.sessionId;
    // Sem sessão não há o que travar: a conversa nova nasce com o modelo no
    // `createConversation`.
    if (sessionId == null) {
      state = state.copyWith(modelId: id, modelProvider: provider);
      return null;
    }

    try {
      final confirmado = await _repo.lockConversationModel(sessionId, pedido);
      state = state.copyWith(
        modelId: confirmado.model,
        modelProvider: confirmado.provider ?? provider,
      );
      ref.invalidate(conversationFeedProvider);
      return null;
    } on ModelLockException catch (recusa) {
      return recusa.message;
    } catch (_) {
      return modelLockFailureMessage(ModelLockFailure.falhaDoServidor, pedido);
    }
  }

  /// Responde a um pedido de aprovação de ferramenta.
  ///
  /// Só é chamado por gesto explícito na tela. Devolve `null` quando o servidor
  /// aceitou, ou a mensagem da recusa: o pedido pode já ter sido respondido por
  /// outro cliente da mesma run, e nesse caso o toque não pode simplesmente
  /// parecer ignorado.
  Future<String?> respondToApproval(ApprovalChoice choice) async {
    final pending = state.pendingApproval;
    if (pending == null) return null;

    try {
      final turn = _gatewayTurn;
      if (turn != null && pending.runId == turn.turnId) {
        await turn.respondToApproval(choice, requestId: pending.requestId);
      } else {
        await _repo.respondToApproval(pending.runId, choice);
      }
      state = state.copyWith(pendingApproval: null, approvalError: null);
      return null;
    } on ApprovalException catch (recusa) {
      // O pedido morreu no servidor, então sai da tela junto com o motivo: um
      // card que não responde a mais nenhum toque seria pior.
      state = state.copyWith(
        pendingApproval: null,
        approvalError: recusa.message,
      );
      return recusa.message;
    } catch (_) {
      final mensagem = approvalFailureMessage(ApprovalFailure.falhaDoServidor);
      state = state.copyWith(approvalError: mensagem);
      return mensagem;
    }
  }

  /// Trava a resposta de uma pergunta do batch por `clarify.lock`. O servidor
  /// é dono do conjunto de respostas; a cópia local espelha o replay e a última
  /// edição, e o último lock resolve o pedido.
  Future<String?> respondToClarification(
    Object answer, {
    required String questionId,
  }) async {
    final pending = state.pendingClarification;
    final turn = _gatewayTurn;
    final validAnswer = answer is String
        ? answer.trim().isNotEmpty
        : answer is List &&
              answer.isNotEmpty &&
              answer.every((item) => item is String);
    if (pending == null || turn == null || !validAnswer) return null;
    final id = questionId.trim();
    if (id.isEmpty ||
        (pending.isAnswered(id) && !pending.canEditAnswer(id)) ||
        !pending.questions.any((question) => question.id == id)) {
      return null;
    }
    try {
      final response = await turn.lockClarification(
        requestId: pending.requestId,
        questionId: id,
        answer: answer,
      );
      if (response.expired) {
        state = state.copyWith(
          pendingClarification: null,
          clarificationError: 'Essa pergunta já expirou no gateway.',
        );
        return null;
      }
      final updated = pending.withAnswer(id, answer);
      final done =
          response.remaining?.isEmpty ??
          updated.questions.every(
            (question) => updated.isAnswered(question.id),
          );
      state = state.copyWith(
        pendingClarification: done ? null : updated,
        clarificationError: null,
      );
      return null;
    } on GatewayOperationException catch (error) {
      state = state.copyWith(clarificationError: error.message);
      return error.message;
    } catch (_) {
      const message = 'O gateway não conseguiu registrar a resposta.';
      state = state.copyWith(clarificationError: message);
      return message;
    }
  }

  void toggleShowActivity() {
    setShowActivity(!state.reasoning.showActivity);
  }

  void setShowActivity(bool show) {
    if (show == state.reasoning.showActivity) return;
    state = state.copyWith(
      reasoning: state.reasoning.copyWith(showActivity: show),
    );
    ref.read(appSettingsProvider.notifier).setShowActivity(show);
  }

  /// As instruções são enviadas como `instructions` somente na próxima run.
  void setInstructions(String value) {
    final instructions = value.trim();
    state = state.copyWith(instructions: instructions);
    ref.read(appSettingsProvider.notifier).setInstructions(instructions);
  }

  Future<void> _rememberActiveRun({
    required String sessionId,
    required String runId,
    required String assistantMessageId,
    required DateTime startedAt,
    String? model,
    ActiveTurnTransport transport = ActiveTurnTransport.runs,
  }) async {
    final record = ActiveRunRecord(
      sessionId: sessionId,
      runId: runId,
      assistantMessageId: assistantMessageId,
      startedAt: startedAt,
      model: _usableModelId(model),
      transport: transport,
    );
    ref.read(activeConversationIdsProvider.notifier).markActive(sessionId);
    _activeRunWrites = _activeRunWrites
        .then((_) => _activeRuns.save(record))
        .catchError((_) {
          // Persistência melhora a retomada, mas nunca pode impedir uma run que
          // o servidor já aceitou de continuar nesta sessão.
        });
    await _activeRunWrites;
  }

  Future<void> _resumeActiveRun(
    String sessionId,
    int epoch, {
    int? listenerGeneration,
  }) async {
    if (!_canListen(epoch, listenerGeneration)) return;
    final ActiveRunRecord? record;
    try {
      record = await _activeRuns.read(sessionId);
    } catch (_) {
      return;
    }
    if (record == null || !_canListen(epoch, listenerGeneration)) return;

    await _resumeActiveRecord(
      record,
      epoch,
      listenerGeneration: listenerGeneration,
    );
  }

  Future<void> _resumeActiveRecord(
    ActiveRunRecord record,
    int epoch, {
    int? listenerGeneration,
  }) async {
    if (!_canListen(epoch, listenerGeneration)) return;

    if (record.transport == ActiveTurnTransport.dashboard) {
      await _resumeActiveGatewayTurn(
        record,
        epoch,
        listenerGeneration: listenerGeneration,
      );
      return;
    }

    final Run run;
    try {
      run = await _repo.getRun(record.runId);
    } catch (error) {
      if (_runWasDiscarded(error)) {
        await _clearActiveRunFor(record.sessionId);
      }
      // Sem snapshot não há base para inventar que a run acabou. O registro fica
      // guardado e a próxima abertura da conversa tenta novamente, exceto no
      // 404 autoritativo: ali o servidor já descartou a run e o histórico que
      // acabamos de carregar é a única fonte restante.
      return;
    }
    if (!_canListen(epoch, listenerGeneration)) return;

    if (run.isTerminal) {
      _applyRecoveredTerminalRun(record, run);
      state = state.copyWith(streaming: false, runId: null);
      await _clearActiveRunFor(record.sessionId);
      ref.invalidate(conversationFeedProvider);
      return;
    }

    // A bolha do turno já foi preservada pela reconstrução do histórico; aqui
    // ela só é criada quando não havia nada na tela, que é o caso de app
    // reaberto. Recriá-la sempre era o que apagava a resposta em andamento.
    _ensureTurnBubble(record);
    state = state.copyWith(streaming: true, runId: record.runId);
    _reasonWatch
      ..reset()
      ..start();
    _listenToRun(record.assistantMessageId, record.runId, epoch);
  }

  Future<List<SessionMessage>> _dashboardConversationHistory(
    String sessionId,
  ) async {
    final gateway = await _pairedGateway();
    if (gateway == null) return const [];
    try {
      return await gateway.conversationHistory(storedSessionId: sessionId);
    } catch (_) {
      // Pareamento expirado, gateway fora do ar ou histórico temporariamente
      // indisponível não apagam o snapshot HTTP já carregado.
      return const [];
    }
  }

  Future<_GatewayTurnStart> _startGatewayTurn({
    required String text,
    required String sessionId,
    required String assistantMessageId,
    required int epoch,
  }) async {
    // O contrato TUI confirmado não tem campo `instructions` por prompt.
    // Ignorar uma preferência explícita seria pior que manter o transporte
    // compatível; Runs segue responsável por esse caso até o runtime anunciar
    // uma forma equivalente.
    if (state.instructions.trim().isNotEmpty) {
      turnCapture.transportFallback('a conversa tem instruções explícitas');
      return _GatewayTurnStart.unavailable;
    }
    if (!_canListen(epoch)) return _GatewayTurnStart.unavailable;
    final listenerGeneration = _listenerGeneration;
    final gateway = await _pairedGateway();
    if (gateway == null) {
      turnCapture.transportFallback('nenhuma sessão pareada do Dashboard');
      return _GatewayTurnStart.unavailable;
    }
    if (!_canListen(epoch, listenerGeneration)) {
      return _GatewayTurnStart.unavailable;
    }

    final GatewayLiveTurn turn;
    try {
      turn = await gateway.openLiveTurn(storedSessionId: sessionId);
    } catch (error) {
      // Nenhum prompt foi enviado: cair para Runs aqui não duplica o turno.
      // Mas cair calado foi o que escondeu A67 por semanas.
      turnCapture.transportFallback(
        'openLiveTurn recusou (${error.runtimeType})',
      );
      return _GatewayTurnStart.unavailable;
    }
    if (!_canListen(epoch, listenerGeneration)) {
      await turn.close();
      return _GatewayTurnStart.unavailable;
    }

    turnCapture.transportHeld();
    _gatewayTurn = turn;
    state = state.copyWith(runId: turn.turnId);
    _patch(
      assistantMessageId,
      (message) => message.copyWith(runId: turn.turnId),
    );
    _listenToGateway(assistantMessageId, turn, epoch);
    await _rememberActiveRun(
      sessionId: sessionId,
      runId: turn.turnId,
      assistantMessageId: assistantMessageId,
      startedAt: DateTime.now(),
      transport: ActiveTurnTransport.dashboard,
    );

    try {
      await turn.submit(text);
      return _GatewayTurnStart.submitted;
    } catch (error) {
      if (epoch == _epoch && !_assistantIsTerminal(assistantMessageId)) {
        _fail(
          assistantMessageId,
          _gatewayError(error),
          epoch: epoch,
          clearActiveRun: true,
        );
      } else {
        await _clearActiveRunFor(sessionId);
      }
      return _GatewayTurnStart.notSubmitted;
    }
  }

  Future<GatewayRepository?> _pairedGateway() async {
    try {
      final gateway = ref.read(gatewayRepositoryProvider);
      return await gateway.hasSession() ? gateway : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _resumeActiveGatewayTurn(
    ActiveRunRecord record,
    int epoch, {
    int? listenerGeneration,
  }) async {
    if (!_canListen(epoch, listenerGeneration)) return;
    final gateway = await _pairedGateway();
    if (gateway == null || !_canListen(epoch, listenerGeneration)) return;
    turnCapture.beginTurn(sessionId: record.sessionId, origin: 'retomada');

    final GatewayLiveTurn turn;
    try {
      turn = await gateway.openLiveTurn(storedSessionId: record.sessionId);
    } catch (error) {
      // Sem isto a captura ficava presa em "observando" para sempre: o
      // `beginTurn` acima já consumiu o armamento, e nada a encerrava.
      turnCapture.transportFallback(
        'retomada recusada pelo TUI (${error.runtimeType})',
      );
      turnCapture.endTurn('retomada não abriu o socket');
      return;
    }
    turnCapture.transportHeld();
    if (!_canListen(epoch, listenerGeneration)) {
      await turn.close();
      turnCapture.endTurn('retomada abandonada');
      return;
    }

    _applyGatewayHistory(turn.initialHistory, record);
    if (!turn.running) {
      await turn.close();
      await _clearActiveRunFor(record.sessionId);
      state = state.copyWith(streaming: false, runId: null);
      ref.invalidate(conversationFeedProvider);
      return;
    }

    _gatewayTurn = turn;
    _ensureTurnBubble(record);
    state = state.copyWith(streaming: true, runId: turn.turnId);
    _reasonWatch
      ..reset()
      ..start();
    _listenToGateway(record.assistantMessageId, turn, epoch);
  }

  /// Reconstrói a lista a partir do histórico **sem perder o turno em curso**.
  ///
  /// A58: nenhum histórico contém o turno em curso, nem o da Runs nem o do
  /// gateway, porque ele só é persistido ao terminar. Reconstruir sem cuidado
  /// apagava o parcial que estava na tela, e era isso que fazia sair e voltar
  /// perder a resposta em andamento.
  ///
  /// Duas situações, e as duas terminam com **uma** bolha:
  ///
  /// - o histórico já fecha com resposta do assistant: ela é este mesmo turno
  ///   parcialmente persistido, então é adotada e reconciliada com o parcial
  ///   local, nunca duplicada;
  /// - o histórico fecha com a fala do usuário: o turno ainda não deixou rastro
  ///   lá, e a bolha local é a única que existe.
  ///
  /// A reconciliação acontece **aqui**, e não num campo guardado entre uma
  /// função e outra: a retomada tem vários caminhos de saída antecipada, e um
  /// parcial esquecido num campo voltaria depois, colado no turno errado.
  List<ChatMessage> _timelineComTurnoEmCurso(
    List<SessionMessage> persisted, {
    required String assistantMessageId,
    String? model,
  }) {
    final viva = _assistantById(assistantMessageId);
    final mensagens = [...conversationTimeline(persisted, model: model)];
    final ultimo = mensagens.lastIndexWhere(
      (message) => message is AssistantMessage,
    );
    if (ultimo >= 0 && ultimo == mensagens.length - 1) {
      mensagens[ultimo] = _mergeResumed(
        mensagens[ultimo] as AssistantMessage,
        viva,
      ).copyWith(id: assistantMessageId);
      return mensagens;
    }
    if (viva != null) mensagens.add(viva);
    return mensagens;
  }

  void _applyGatewayHistory(
    List<SessionMessage> history,
    ActiveRunRecord record,
  ) {
    if (history.isEmpty) return;
    final resumed = _timelineComTurnoEmCurso(
      history,
      assistantMessageId: record.assistantMessageId,
      model: _usableModelId(record.model),
    );
    state = state.copyWith(
      messages: _reconcileGatewayTimeline(resumed, record),
    );
  }

  /// Um socket retomado pode começar com um recorte do turno ativo, enquanto
  /// a hidratação HTTP já publicou a conversa inteira. O recorte atualiza a
  /// última resposta, mas nunca tem autoridade para apagar o prefixo visível.
  List<ChatMessage> _reconcileGatewayTimeline(
    List<ChatMessage> resumed,
    ActiveRunRecord record,
  ) {
    final current = state.messages;
    if (current.isEmpty) return resumed;

    final resumedUser = resumed.lastIndexWhere(
      (message) => message is UserMessage,
    );
    if (resumedUser < 0) {
      return resumed.length > current.length ? resumed : current;
    }
    final resumedPrompt = resumed[resumedUser] as UserMessage;
    bool samePrompt(ChatMessage message, UserMessage prompt) =>
        message is UserMessage &&
        (message.id == prompt.id ||
            (message.text == prompt.text &&
                message.scaffolding == prompt.scaffolding));
    final currentUser = current.lastIndexWhere(
      (message) => samePrompt(message, resumedPrompt),
    );

    if (currentUser < 0) {
      final latestCurrentUser = current.lastIndexWhere(
        (message) => message is UserMessage,
      );
      if (latestCurrentUser >= 0) {
        final currentPrompt = current[latestCurrentUser] as UserMessage;
        final resumedContainsCurrent = resumed.any(
          (message) => samePrompt(message, currentPrompt),
        );
        if (resumedContainsCurrent) return resumed;
      } else {
        final onlyLiveBubble = current.any(
          (message) =>
              message is AssistantMessage &&
              message.id == record.assistantMessageId,
        );
        // Ao voltar do background, o refresh HTTP pode ainda não conter nem a
        // pergunta e preservar apenas a bolha local. `resumed` já reconciliou
        // essa bolha; concatená-la aqui criaria assistant/user/assistant.
        if (onlyLiveBubble) return resumed;
      }
      // Sem uma âncora comum, o snapshot live é um sufixo novo que o histórico
      // HTTP ainda não conhece. Mantemos o prefixo e acrescentamos esse turno.
      return [...current, ...resumed];
    }

    final latestCurrentUser = current.lastIndexWhere(
      (message) => message is UserMessage,
    );
    if (currentUser != latestCurrentUser) return current;
    if (resumed.length >= current.length) return resumed;

    final merged = [...current];
    final currentAssistant = merged.lastIndexWhere(
      (message) => message is AssistantMessage,
    );
    final resumedAssistant = resumed.lastIndexWhere(
      (message) => message is AssistantMessage,
    );
    final belongsToActiveTurn = currentAssistant > currentUser;

    if (belongsToActiveTurn) {
      final local = merged[currentAssistant] as AssistantMessage;
      final incoming = resumedAssistant > resumedUser
          ? resumed[resumedAssistant] as AssistantMessage
          : null;
      merged[currentAssistant] =
          (incoming == null ? local : _mergeResumed(incoming, local)).copyWith(
            id: record.assistantMessageId,
          );
    } else if (resumedAssistant > resumedUser) {
      merged.add(resumed[resumedAssistant]);
    }
    return merged;
  }

  /// Deixa a bolha do turno pronta para receber o stream, nos dois transportes.
  ///
  /// Ela já costuma existir, adotada ou preservada por
  /// [_timelineComTurnoEmCurso]; aqui só a fase e o vínculo com a run são
  /// acertados. Criar do zero é o caso de app reaberto, sem nada na tela.
  void _ensureTurnBubble(ActiveRunRecord record) {
    final existente = _assistantById(record.assistantMessageId);
    if (existente != null) {
      _patch(
        record.assistantMessageId,
        (message) => message.copyWith(
          phase: message.text.isEmpty ? ChatPhase.reasoning : ChatPhase.writing,
          runId: record.runId,
        ),
      );
      return;
    }
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage.assistant(
          id: record.assistantMessageId,
          phase: state.reasoning.showActivity
              ? ChatPhase.reasoning
              : ChatPhase.writing,
          time: _hhmmFrom(record.startedAt),
          model: _usableModelId(record.model),
          runId: record.runId,
        ),
      ],
    );
  }

  /// Reconcilia as duas visões do **mesmo** turno.
  ///
  /// O servidor persiste ao concluir; o app acumula enquanto ouve. Nenhum dos
  /// dois é sempre o mais completo: voltando do background o local está à
  /// frente, e depois de fechar o app ele está vazio. Reconciliar é ficar com
  /// o mais completo de cada lado, nunca com o mais curto. Perder texto que já
  /// esteve na tela é exatamente o defeito que A58 persegue.
  AssistantMessage _mergeResumed(
    AssistantMessage persistido,
    AssistantMessage? local,
  ) {
    if (local == null) return persistido;
    String maior(String a, String b) => a.length >= b.length ? a : b;
    return persistido.copyWith(
      text: maior(persistido.text, local.text),
      reasoning: maior(persistido.reasoning, local.reasoning),
      activity: maior(persistido.activity, local.activity),
      activityItems:
          persistido.activityItems.length >= local.activityItems.length
          ? persistido.activityItems
          : local.activityItems,
      tools: persistido.tools.length >= local.tools.length
          ? persistido.tools
          : local.tools,
      reasonTime: persistido.reasonTime ?? local.reasonTime,
      model: persistido.model ?? local.model,
    );
  }

  void _applyRecoveredTerminalRun(ActiveRunRecord record, Run run) {
    final output = run.output?.trim() ?? '';
    final last = _lastAssistant();
    final alreadyVisible =
        output.isNotEmpty && last != null && last.text.trim() == output;
    if (alreadyVisible) return;

    switch (run.status) {
      case RunStatus.completed when output.isNotEmpty:
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage.assistant(
              id: record.assistantMessageId,
              phase: ChatPhase.done,
              text: output,
              time: _hhmmFrom(record.startedAt),
              model: _usableModelId(record.model),
              runId: record.runId,
            ),
          ],
        );
      case RunStatus.failed:
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage.assistant(
              id: record.assistantMessageId,
              phase: ChatPhase.failed,
              time: _hhmmFrom(record.startedAt),
              model: _usableModelId(record.model),
              runId: record.runId,
              error: run.error ?? 'A run falhou antes de o app ser reaberto.',
            ),
          ],
        );
      case RunStatus.cancelled:
        state = state.copyWith(
          messages: [
            ...state.messages,
            ChatMessage.assistant(
              id: record.assistantMessageId,
              phase: ChatPhase.cancelled,
              time: _hhmmFrom(record.startedAt),
              model: _usableModelId(record.model),
              runId: record.runId,
            ),
          ],
        );
      default:
        break;
    }
  }

  void _clearActiveRun() {
    final sessionId = state.sessionId;
    if (sessionId != null) unawaited(_clearActiveRunFor(sessionId));
  }

  Future<void> _clearActiveRunFor(String sessionId) async {
    ref.read(activeConversationIdsProvider.notifier).markInactive(sessionId);
    _activeRunWrites = _activeRunWrites
        .then((_) => _activeRuns.clear(sessionId))
        .catchError((_) {
          // Registro terminal obsoleto é inofensivo: na próxima abertura o
          // snapshot terminal será reconhecido e a limpeza tentará de novo.
        });
    await _activeRunWrites;
  }

  void _listenToGateway(String messageId, GatewayLiveTurn turn, int epoch) {
    if (!_canListen(epoch)) return;
    final generation = _listenerGeneration;
    var reconciling = false;

    void reconcile() {
      if (reconciling ||
          !_canListen(epoch, generation) ||
          _assistantIsTerminal(messageId)) {
        return;
      }
      reconciling = true;
      unawaited(
        _reconcileGatewayAfterDisconnect(messageId, turn, epoch, generation),
      );
    }

    _sub = turn.events.listen(
      (event) {
        if (_canListen(epoch, generation)) {
          _onEvent(messageId, event, epoch);
        }
      },
      onError: (Object _) => reconcile(),
      onDone: reconcile,
    );
  }

  Future<void> _reconcileGatewayAfterDisconnect(
    String messageId,
    GatewayLiveTurn disconnected,
    int epoch,
    int generation,
  ) async {
    if (identical(_gatewayTurn, disconnected)) _gatewayTurn = null;
    await disconnected.close();

    Object? lastError;
    for (var attempt = 0; attempt < 5; attempt++) {
      if (!_canListen(epoch, generation) || _assistantIsTerminal(messageId)) {
        return;
      }
      if (attempt > 0) {
        final base = ref.read(runReconciliationDelayProvider);
        final delay = base * (1 << (attempt - 1));
        await Future<void>.delayed(
          delay > const Duration(seconds: 2)
              ? const Duration(seconds: 2)
              : delay,
        );
        if (!_canListen(epoch, generation) || _assistantIsTerminal(messageId)) {
          return;
        }
      }

      try {
        final gateway = await _pairedGateway();
        if (gateway == null) {
          throw const GatewayAuthenticationRequired();
        }
        final resumed = await gateway.openLiveTurn(
          storedSessionId: disconnected.storedSessionId,
        );
        if (!_canListen(epoch, generation) || _assistantIsTerminal(messageId)) {
          await resumed.close();
          return;
        }

        final record = ActiveRunRecord(
          sessionId: disconnected.storedSessionId,
          runId: resumed.turnId,
          assistantMessageId: messageId,
          startedAt: DateTime.now(),
          model: state.modelId,
          transport: ActiveTurnTransport.dashboard,
        );
        _applyGatewayHistory(resumed.initialHistory, record);
        if (!resumed.running) {
          await resumed.close();
          await _clearActiveRunFor(disconnected.storedSessionId);
          _finish(epoch);
          ref.invalidate(conversationFeedProvider);
          return;
        }

        _gatewayTurn = resumed;
        _ensureTurnBubble(record);
        state = state.copyWith(streaming: true, runId: resumed.turnId);
        await _rememberActiveRun(
          sessionId: disconnected.storedSessionId,
          runId: resumed.turnId,
          assistantMessageId: messageId,
          startedAt: record.startedAt,
          model: record.model,
          transport: ActiveTurnTransport.dashboard,
        );
        _listenToGateway(messageId, resumed, epoch);
        return;
      } catch (error) {
        lastError = error;
      }
    }

    if (_canListen(epoch, generation) && !_assistantIsTerminal(messageId)) {
      _fail(messageId, _gatewayError(lastError), epoch: epoch);
    }
  }

  void _listenToRun(String messageId, String runId, int epoch) {
    if (!_canListen(epoch)) return;
    final generation = _listenerGeneration;
    var reconciling = false;

    void reconcile() {
      if (reconciling || !_canListen(epoch, generation)) return;
      reconciling = true;
      unawaited(_reconcileAfterStream(messageId, runId, epoch, generation));
    }

    _sub = _repo
        .runEvents(runId)
        .listen(
          (event) {
            if (_canListen(epoch, generation)) {
              _onEvent(messageId, event, epoch);
            }
          },
          // Uma queda depois que o SSE abriu não diz que a run falhou. O
          // snapshot é a fonte autoritativa; encerrar a bolha aqui transformava
          // oscilação de rede em "Resposta inesperada" no celular.
          onError: (Object _) => reconcile(),
          onDone: reconcile,
        );
  }

  void _onEvent(String id, RunEvent event, int epoch) {
    turnCapture.adapterEvent(event);
    switch (event) {
      case RunActivityPreview(:final text):
        if (!state.reasoning.showActivity) {
          return;
        }
        _patch(
          id,
          (message) => message.copyWith(
            phase: ChatPhase.reasoning,
            activity: message.activity + text,
            activityItems: text.isEmpty
                ? message.activityItems
                : [
                    ...message.activityItems,
                    TurnActivity.activity(id: _nextTurnEventId(id), text: text),
                  ],
          ),
        );
      // Estado, não conteúdo: substitui o anterior em vez de empilhar, e some
      // quando o gateway manda texto vazio. Nunca entra em `activityItems`,
      // que é o que a conversa reaberta reconstrói.
      case RunThinkingState(:final text):
        if (!state.reasoning.showActivity) return;
        _patch(id, (message) => message.copyWith(thinking: text));
      case RunReasoningDelta(:final text):
        if (!state.reasoning.showActivity || text.isEmpty) return;
        _patch(
          id,
          (message) => message.copyWith(
            phase: ChatPhase.reasoning,
            reasoning: message.reasoning + text,
            activityItems: _appendReasoningDelta(
              message.activityItems,
              id,
              text,
            ),
          ),
        );
      case RunToolProgress(:final tool):
        if (tool.name == '_thinking' && !state.reasoning.showActivity) return;
        _patch(
          id,
          (message) => message.copyWith(
            phase: ChatPhase.writing,
            reasonTime: message.reasonTime ?? _elapsed(),
            tools: applyToolEvent(message.tools, tool),
            activityItems: applyTurnToolEvent(
              message.activityItems,
              tool,
              blockId: _nextTurnEventId(id),
            ),
          ),
        );
      case RunTextDelta(:final text):
        _patch(
          id,
          (message) => message.copyWith(
            phase: ChatPhase.writing,
            reasonTime: message.reasonTime ?? _elapsed(),
            text: message.text + text,
          ),
        );
      // Nada é decidido aqui: só registramos o pedido e a tela espera o gesto.
      case RunApprovalRequest(:final request):
        state = state.copyWith(pendingApproval: request, approvalError: null);
      case RunApprovalResolved():
        // Pode ter sido resolvido por outro cliente da mesma run.
        state = state.copyWith(pendingApproval: null, approvalError: null);
      case RunClarifyRequest(:final request):
        state = state.copyWith(
          pendingClarification: request,
          clarificationError: null,
        );
      case RunClarifyResolved():
        state = state.copyWith(
          pendingClarification: null,
          clarificationError: null,
        );
      case RunStatusEvent(:final status):
        if (status == RunStatus.cancelled) {
          _patch(
            id,
            (message) =>
                message.copyWith(phase: ChatPhase.cancelled, thinking: ''),
          );
          turnCapture.endTurn('turno interrompido');
          _clearActiveRun();
          _finish(epoch);
        }
      case RunCompleted(:final output):
        _patch(
          id,
          (message) => message.copyWith(
            phase: ChatPhase.done,
            text: output?.isNotEmpty == true ? output! : message.text,
            tools: settleTools(message.tools),
            activityItems: settleTurnTools(message.activityItems),
            thinking: '',
          ),
        );
        _captureTurnEnd(id);
        _clearActiveRun();
        _finish(epoch);
        ref.invalidate(conversationFeedProvider);
      case RunFailed(:final error):
        _fail(id, error ?? 'Falha na run', epoch: epoch, clearActiveRun: true);
      case RunUnknown(:final type, :final data):
        if (type != 'request.cancel') break;
        final requestId = data['id'];
        if (requestId is! String || requestId.isEmpty) break;
        if (state.pendingApproval?.requestId == requestId) {
          state = state.copyWith(pendingApproval: null, approvalError: null);
        }
        if (state.pendingClarification?.requestId == requestId) {
          state = state.copyWith(
            pendingClarification: null,
            clarificationError: null,
          );
        }
    }
  }

  /// Fecha a captura comparando as duas projeções do **mesmo** turno.
  ///
  /// A projeção ao vivo é o que o stream conseguiu montar; a do histórico é a
  /// que a pessoa vê ao reabrir a conversa. Buscar o histórico aqui é o que
  /// transforma a captura em diagnóstico: sem ele sobra um dump de eventos que
  /// não diz de qual camada veio a perda. Nada disto pode afetar o turno.
  void _captureTurnEnd(String messageId) {
    if (!turnCapture.capturing) return;
    final message = _assistantById(messageId);
    if (message != null) turnCapture.liveProjection(message.activityItems);
    unawaited(_captureHistoryProjection());
  }

  Future<void> _captureHistoryProjection() async {
    final sessionId = state.sessionId;
    if (sessionId == null) {
      turnCapture.endTurn('sem sessão para comparar');
      return;
    }
    try {
      final persisted = await _repo.conversationMessages(sessionId);
      final timeline = conversationTimeline(persisted, model: state.modelId);
      final last = timeline.lastWhere(
        (message) => message is AssistantMessage,
        orElse: () => const ChatMessage.assistant(id: 'captura-vazia'),
      );
      if (last is AssistantMessage) {
        turnCapture.historyProjection(last.activityItems);
      }
      turnCapture.endTurn('turno concluído');
    } catch (_) {
      turnCapture.endTurn('histórico indisponível');
    }
  }

  List<TurnActivity> _appendReasoningDelta(
    List<TurnActivity> current,
    String messageId,
    String delta,
  ) {
    if (current.isNotEmpty && current.last is TurnReasoning) {
      final last = current.last as TurnReasoning;
      return [
        ...current.take(current.length - 1),
        last.copyWith(text: last.text + delta),
      ];
    }
    return [
      ...current,
      TurnActivity.reasoning(id: _nextTurnEventId(messageId), text: delta),
    ];
  }

  Future<void> _reconcileAfterStream(
    String messageId,
    String runId,
    int epoch,
    int generation,
  ) async {
    if (!_canListen(epoch, generation)) return;
    final message = _assistantById(messageId);
    if (message == null || _isTerminal(message.phase)) {
      _finish(epoch);
      return;
    }

    const maxDelay = Duration(seconds: 2);
    var attempt = 0;
    var consecutiveFailures = 0;
    while (_canListen(epoch, generation) && !_assistantIsTerminal(messageId)) {
      if (attempt > 0) {
        final baseDelay = ref.read(runReconciliationDelayProvider);
        // Depois de quatro passos o teto já manda; limitar o expoente também
        // evita overflow numa run que trabalhe por muitos minutos.
        final exponent = attempt > 5 ? 4 : attempt - 1;
        final backoff = baseDelay * (1 << exponent);
        final delay = backoff > maxDelay ? maxDelay : backoff;
        await Future<void>.delayed(delay);
        if (!_canListen(epoch, generation) || _assistantIsTerminal(messageId)) {
          return;
        }
      }

      try {
        final run = await _repo.getRun(runId);
        consecutiveFailures = 0;
        if (!_canListen(epoch, generation) || _assistantIsTerminal(messageId)) {
          return;
        }
        if (_applyTerminalRunSnapshot(messageId, run, epoch)) return;
      } catch (error) {
        if (_runWasDiscarded(error)) {
          await _recoverFromConversationHistory(messageId, epoch, generation);
          return;
        }
        consecutiveFailures++;
        // Uma oscilação curta não encerra uma run que continua no servidor.
        // Depois de cinco consultas sem sequer alcançar o snapshot, mostramos a
        // causa legível; o registro durável permanece para nova retomada.
        if (consecutiveFailures >= 5) {
          if (_canListen(epoch, generation) &&
              !_assistantIsTerminal(messageId)) {
            _fail(messageId, _legivel(error), epoch: epoch);
          }
          return;
        }
      }
      attempt++;
    }
  }

  bool _runWasDiscarded(Object error) =>
      error is HermesFailure && error.kind == HermesFailureKind.naoEncontrado;

  Future<void> _recoverFromConversationHistory(
    String messageId,
    int epoch,
    int generation,
  ) async {
    final sessionId = state.sessionId;
    if (sessionId == null || !_canListen(epoch, generation)) return;

    try {
      final persisted = await _repo.conversationMessages(sessionId);
      if (!_canListen(epoch, generation)) return;
      state = state.copyWith(
        streaming: false,
        runId: null,
        messages: conversationTimeline(persisted, model: state.modelId),
      );
      await _clearActiveRunFor(sessionId);
      ref.invalidate(conversationFeedProvider);
    } catch (_) {
      if (!_canListen(epoch, generation)) return;
      // Mesmo se o histórico estiver temporariamente indisponível, o 404 da run
      // não pode virar uma falsa falha do Hermes. Preserva qualquer delta útil e
      // remove apenas a bolha vazia criada para a retomada.
      final current = _assistantById(messageId);
      state = state.copyWith(
        streaming: false,
        runId: null,
        messages: current != null && current.text.trim().isEmpty
            ? state.messages
                  .where((message) => message.id != messageId)
                  .toList()
            : state.messages,
      );
      await _clearActiveRunFor(sessionId);
    }
  }

  bool _applyTerminalRunSnapshot(String messageId, Run run, int epoch) {
    switch (run.status) {
      case RunStatus.completed:
        _patch(
          messageId,
          (current) => current.copyWith(
            phase: ChatPhase.done,
            text: run.output?.isNotEmpty == true ? run.output! : current.text,
            tools: settleTools(current.tools),
            activityItems: settleTurnTools(current.activityItems),
            thinking: '',
          ),
        );
        _captureTurnEnd(messageId);
        _clearActiveRun();
        _finish(epoch);
        ref.invalidate(conversationFeedProvider);
        return true;
      case RunStatus.cancelled:
        _patch(
          messageId,
          (current) =>
              current.copyWith(phase: ChatPhase.cancelled, thinking: ''),
        );
        _clearActiveRun();
        _finish(epoch);
        return true;
      case RunStatus.failed:
        _fail(
          messageId,
          run.error ?? 'Falha na run',
          epoch: epoch,
          clearActiveRun: true,
        );
        return true;
      default:
        return false;
    }
  }

  bool _assistantIsTerminal(String id) {
    final message = _assistantById(id);
    return message == null || _isTerminal(message.phase);
  }

  /// Traduz qualquer erro na frase que vai aparecer dentro da bolha.
  ///
  /// O adapter já entrega [HermesFailure]; isto aqui é a última linha de
  /// defesa, para nunca cair `toString` de exceção na conversa. Ver A7.
  String _legivel(Object error) {
    if (error is GatewayOperationException) return error.message;
    final falha = hermesFailureFrom(error);
    return '${falha.title}. ${falha.hint}';
  }

  String _gatewayError(Object? error) => switch (error) {
    GatewayOperationException(:final message) => message,
    _ => 'O live chat perdeu a conexão e não conseguiu retomar.',
  };

  void _fail(
    String id,
    String error, {
    int? epoch,
    bool clearActiveRun = false,
  }) {
    if (epoch != null && epoch != _epoch) return;
    turnCapture.endTurn('turno falhou');
    _patch(
      id,
      (message) => message.copyWith(
        phase: ChatPhase.failed,
        error: error,
        tools: settleTools(message.tools, failed: true),
        activityItems: settleTurnTools(message.activityItems, failed: true),
        thinking: '',
      ),
    );
    if (clearActiveRun) _clearActiveRun();
    _finish(epoch);
  }

  void _failCurrentAssistant(String error) {
    final message = _lastAssistant();
    if (message != null) _fail(message.id, error);
  }

  void _finish([int? epoch]) {
    if (epoch != null && epoch != _epoch) return;
    _reasonWatch.stop();
    // Run encerrada mata a pendência de aprovação junto: um card pedindo decisão
    // sobre uma run que já terminou não tem mais a quem responder.
    if (state.streaming ||
        state.pendingApproval != null ||
        state.pendingClarification != null) {
      state = state.copyWith(
        streaming: false,
        pendingApproval: null,
        pendingClarification: null,
      );
    }
    unawaited(_closeGatewayTurn());
  }

  void _finishFlagsOnly() => _reasonWatch.stop();

  Future<void> _closeGatewayTurn() async {
    final turn = _gatewayTurn;
    _gatewayTurn = null;
    await turn?.close();
  }

  void _patch(String id, AssistantMessage Function(AssistantMessage) update) {
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message is AssistantMessage && message.id == id)
            update(message)
          else
            message,
      ],
    );
  }

  AssistantMessage? _assistantById(String id) {
    for (final message in state.messages) {
      if (message is AssistantMessage && message.id == id) return message;
    }
    return null;
  }

  AssistantMessage? _lastAssistant() {
    for (final message in state.messages.reversed) {
      if (message is AssistantMessage) return message;
    }
    return null;
  }

  String _nextTurnEventId(String messageId) =>
      '${messageId}_event_${_turnEventSerial++}';

  bool _isTerminal(ChatPhase phase) => switch (phase) {
    ChatPhase.done || ChatPhase.cancelled || ChatPhase.failed => true,
    ChatPhase.reasoning || ChatPhase.writing => false,
  };

  Future<void> _updateTitle(String sessionId, String title) async {
    try {
      await _repo.updateConversation(sessionId, title: title);
      ref.invalidate(conversationFeedProvider);
    } catch (_) {
      // A run continua útil mesmo se a atualização do título falhar.
    }
  }

  List<Map<String, dynamic>> _history(List<ChatMessage> messages) {
    final history = <Map<String, dynamic>>[];
    for (final message in messages) {
      switch (message) {
        // Turno de usuário vazio não é replicado para o servidor. `POST /v1/runs`
        // recusa `input` vazio com 400, mas **não** valida o conteúdo de
        // `conversation_history`: mandar `{"role":"user","content":""}` ali faria
        // o turno vazio ser persistido de novo a cada run. Ver A19.
        case UserMessage(:final text) when text.trim().isNotEmpty:
          history.add({'role': 'user', 'content': text});
        case UserMessage():
          break;
        case AssistantMessage(:final text) when text.isNotEmpty:
          history.add({'role': 'assistant', 'content': text});
        case AssistantMessage():
          break;
      }
    }
    return history;
  }

  String _titleFrom(String text) =>
      text.length > 34 ? '${text.substring(0, 34)}…' : text;

  String _elapsed() =>
      '${(_reasonWatch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s';

  int _idSeed = 0;

  String _uid() {
    _idSeed++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idSeed';
  }

  String _hhmm() {
    return _hhmmFrom(DateTime.now());
  }

  String _hhmmFrom(DateTime raw) {
    final now = raw.toLocal();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}
