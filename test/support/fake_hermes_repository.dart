import 'dart:async';

import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/capabilities.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/conversation_page.dart';
import 'package:hermes_mobile/domain/models/health_status.dart';
import 'package:hermes_mobile/domain/models/hermes_model.dart';
import 'package:hermes_mobile/domain/models/hermes_provider.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/domain/models/hermes_toolset.dart';
import 'package:hermes_mobile/domain/models/model_lock.dart';
import 'package:hermes_mobile/domain/models/model_options.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/repositories/hermes_repository.dart';

/// Stream deliberadamente controlável que continua notificando após [cancel].
/// Isto permite testar callbacks que chegaram tarde de uma sessão anterior.
class ControlledRunStream extends Stream<RunEvent> {
  void Function(RunEvent)? _onData;
  Function? _onError;
  void Function()? _onDone;
  int listenCount = 0;
  int cancelCount = 0;

  bool get hasListener => _onData != null;

  @override
  bool get isBroadcast => false;

  void add(RunEvent event) => _onData?.call(event);

  void addError(Object error) => _onError?.call(error);

  void close() => _onDone?.call();

  @override
  StreamSubscription<RunEvent> listen(
    void Function(RunEvent)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    listenCount++;
    _onData = onData;
    _onError = onError;
    _onDone = onDone;
    return _ControlledRunSubscription(() => cancelCount++);
  }
}

class _ControlledRunSubscription implements StreamSubscription<RunEvent> {
  _ControlledRunSubscription(this._onCancel);

  final void Function() _onCancel;
  var _cancelled = false;

  @override
  Future<void> cancel() async {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel();
  }

  @override
  bool get isPaused => false;

  @override
  void onData(void Function(RunEvent)? handleData) {}

  @override
  void onDone(void Function()? handleDone) {}

  @override
  void onError(Function? handleError) {}

  @override
  void pause([Future<void>? resumeSignal]) {}

  @override
  void resume() {}

  @override
  Future<E> asFuture<E>([E? futureValue]) => Completer<E>().future;
}

/// Fake de teste, restrito a `test/`, para exercitar controllers e widgets sem rede.
class FakeHermesRepository implements HermesRepository {
  FakeHermesRepository({
    this.answer = 'Resposta real de teste.',
    this.emitsToolCompletion = true,
    List<ControlledRunStream>? controlledStreams,
    List<Run>? runSnapshots,
    List<Object>? runSnapshotResults,
    List<Conversation>? conversations,
    Map<String, List<SessionMessage>>? messages,
    List<HermesSkill>? skills,
    this.skillsFailure,
    this.conversationMessagesHandler,
    this.conversationPageFailure,
  }) : _conversations = List<Conversation>.of(
         conversations ?? _defaultConversations,
       ),
       _messages = messages ?? _defaultMessages(),
       _skills = List<HermesSkill>.of(
         skills ??
             const [
               HermesSkill(name: 'hermes-agent', description: 'Skill de teste'),
             ],
       ),
       _controlledStreams = List<ControlledRunStream>.of(
         controlledStreams ?? const [],
       ),
       _runSnapshotResults = List<Object>.of(
         runSnapshotResults ?? runSnapshots ?? const [],
       );

  final String answer;
  final bool emitsToolCompletion;
  final Future<List<SessionMessage>> Function(String sessionId)?
  conversationMessagesHandler;

  /// Falha imposta ao paginar a lista, para reproduzir servidor fora de
  /// alcance sem depender de rede.
  final Object? conversationPageFailure;
  final Object? skillsFailure;
  final List<HermesSkill> _skills;
  final List<ControlledRunStream> _controlledStreams;
  final List<Object> _runSnapshotResults;
  int _nextRunSnapshot = 0;
  int _nextConversation = 1;
  int _nextRun = 1;
  static Map<String, List<SessionMessage>> _defaultMessages() => {
    'session-1': [
      SessionMessage(
        id: 'message-1',
        role: 'user',
        content: 'Mensagem persistida',
        timestamp: DateTime.utc(2026, 7, 15, 9, 30),
      ),
      SessionMessage(
        id: 'message-2',
        role: 'assistant',
        content: 'Resposta persistida',
        timestamp: DateTime.utc(2026, 7, 15, 9, 31),
      ),
    ],
  };
  static final _defaultConversations = [
    Conversation(
      id: 'session-1',
      title: 'Conversa persistida',
      preview: 'Resposta persistida',
      model: 'gpt-5.6-terra',
      provider: 'openai-codex',
      lastActive: DateTime.utc(2026, 7, 15, 9, 31),
      messageCount: 2,
    ),
  ];
  final List<Conversation> _conversations;
  final Map<String, List<SessionMessage>> _messages;

  @override
  Future<HealthStatus> health() async => const HealthStatus(status: 'ok');

  @override
  Future<Capabilities> capabilities() async => const Capabilities(
    platform: 'hermes-agent',
    model: 'hermes-agent',
    features: CapabilityFeatures(
      runSubmission: true,
      runStatus: true,
      runEventsSse: true,
      runStop: true,
      sessionResources: true,
    ),
  );

  @override
  Future<List<HermesModel>> models() async => const [
    HermesModel(id: 'hermes-agent', ownedBy: 'test'),
  ];

  /// Respostas de aprovação enviadas, na ordem.
  final List<ApprovalChoice> aprovacoes = [];

  /// Históricos mandados em cada `createRun`, na ordem.
  final List<List<Map<String, dynamic>>> historicos = [];

  /// Quando não nulo, a próxima criação de run falha antes de ser aceita.
  Object? falhaAoCriarRun;

  /// Quando não nulo, a próxima resposta de aprovação falha assim.
  ApprovalFailure? recusaAprovacao;

  @override
  Future<void> respondToApproval(String runId, ApprovalChoice choice) async {
    final falha = recusaAprovacao;
    if (falha != null) {
      recusaAprovacao = null;
      throw ApprovalException(falha);
    }
    aprovacoes.add(choice);
  }

  /// Pares que o fake recusa, para exercitar o `409` sem servidor.
  final Set<String> recusa = {};

  /// Últimos pedidos de trava, na ordem, para o teste provar que houve chamada.
  final List<ModelLock> travas = [];

  @override
  Future<ModelLock> lockConversationModel(
    String sessionId,
    ModelLock lock,
  ) async {
    travas.add(lock);
    if (recusa.contains(lock.label)) {
      throw ModelLockException(
        failure: ModelLockFailure.naoRoteavel,
        requested: lock,
      );
    }
    final index = _conversations.indexWhere((item) => item.id == sessionId);
    if (index >= 0) {
      _conversations[index] = _conversations[index].copyWith(
        model: lock.model,
        provider: lock.provider,
      );
    }
    return lock;
  }

  /// Cada chamada ao inventário, com o valor de `refresh`. O A21.4 depende de o
  /// gesto de atualizar de fato pedir catálogo ao vivo.
  final List<bool> inventarios = [];

  /// Inventário devolvido quando `refresh` é verdadeiro, se o teste quiser
  /// distinguir o catálogo em cache do catálogo ao vivo.
  ModelOptions? inventarioAtualizado;

  /// Quando não nulo, a próxima atualização falha assim.
  Object? falhaAoAtualizar;

  @override
  Future<ModelOptions> modelOptions({bool refresh = false}) async {
    inventarios.add(refresh);
    if (refresh) {
      final falha = falhaAoAtualizar;
      if (falha != null) {
        falhaAoAtualizar = null;
        throw falha;
      }
      final atualizado = inventarioAtualizado;
      if (atualizado != null) return atualizado;
    }
    return const ModelOptions(
      model: 'gpt-5.6-terra',
      provider: 'openai-codex',
      providers: [
        HermesProvider(
          id: 'openai-codex',
          name: 'OpenAI Codex',
          models: ['gpt-5.6-terra'],
          totalModels: 1,
          isCurrent: true,
          authenticated: true,
        ),
      ],
    );
  }

  @override
  Future<List<HermesSkill>> skills() async {
    final failure = skillsFailure;
    if (failure != null) throw failure;
    return List<HermesSkill>.unmodifiable(_skills);
  }

  @override
  Future<List<HermesToolset>> toolsets() async => const [
    HermesToolset(
      name: 'terminal',
      label: 'Terminal',
      enabled: true,
      configured: true,
      tools: ['terminal'],
    ),
  ];

  @override
  Future<ConversationPage> conversationPage({
    int limit = 50,
    int offset = 0,
    String? source,
  }) async {
    final failure = conversationPageFailure;
    if (failure != null) throw failure;
    final matching = source == null
        ? _conversations
        : _conversations.where((item) => item.source == source).toList();
    final items = matching.skip(offset).take(limit).toList(growable: false);
    return ConversationPage(
      items: items,
      limit: limit,
      offset: offset,
      hasMore: offset + items.length < matching.length,
    );
  }

  @override
  Future<Conversation> getConversation(String sessionId) async {
    return _conversations.firstWhere((item) => item.id == sessionId);
  }

  @override
  Future<List<Conversation>> listConversations({int limit = 100}) async =>
      _conversations.take(limit).toList(growable: false);

  @override
  Future<Conversation> createConversation({
    String? title,
    String? model,
    String? provider,
  }) async {
    final id = 'session-${++_nextConversation}';
    final conversation = Conversation(
      id: id,
      title: title ?? 'Nova conversa',
      model: model,
      provider: provider,
    );
    criacoes.add(
      model == null ? null : ModelLock(model: model, provider: provider),
    );
    _conversations.insert(0, conversation);
    _messages[id] = <SessionMessage>[];
    return conversation;
  }

  @override
  Future<List<SessionMessage>> conversationMessages(String sessionId) async {
    final handler = conversationMessagesHandler;
    if (handler != null) return handler(sessionId);
    return List<SessionMessage>.unmodifiable(_messages[sessionId] ?? const []);
  }

  @override
  Future<Conversation> updateConversation(
    String sessionId, {
    String? title,
  }) async {
    final index = _conversations.indexWhere((item) => item.id == sessionId);
    if (index < 0) throw StateError('Sessão ausente: $sessionId');
    final updated = _conversations[index].copyWith(
      title: title ?? 'Nova conversa',
    );
    _conversations[index] = updated;
    return updated;
  }

  @override
  Future<Conversation> forkConversation(
    String sessionId, {
    String? title,
  }) async {
    final original = _conversations.firstWhere((item) => item.id == sessionId);
    final conversation = Conversation(
      id: 'session-${++_nextConversation}',
      title: title ?? '${original.title} (ramo)',
      model: original.model,
      provider: original.provider,
      parentSessionId: original.id,
    );
    _conversations.insert(0, conversation);
    _messages[conversation.id] = List<SessionMessage>.of(
      _messages[sessionId] ?? const [],
    );
    return conversation;
  }

  @override
  Future<void> deleteConversation(String sessionId) async {
    _conversations.removeWhere((item) => item.id == sessionId);
    _messages.remove(sessionId);
  }

  @override
  Future<Run> createRun({
    required String input,
    String? sessionId,
    String? instructions,
    String? model,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    final falha = falhaAoCriarRun;
    if (falha != null) {
      falhaAoCriarRun = null;
      throw falha;
    }
    historicos.add(
      List<Map<String, dynamic>>.of(conversationHistory ?? const []),
    );
    modelosRuns.add(model);
    final runId = 'run-${_nextRun++}';
    if (sessionId != null) {
      final list = _messages.putIfAbsent(sessionId, () => <SessionMessage>[]);
      list.add(SessionMessage(id: '$runId-user', role: 'user', content: input));
      list.add(
        SessionMessage(
          id: '$runId-assistant',
          role: 'assistant',
          content: answer,
        ),
      );
    }
    return Run(
      runId: runId,
      status: RunStatus.started,
      sessionId: sessionId,
      model: model,
    );
  }

  /// Pares usados na criação de sessão, inclusive ausência de override.
  final List<ModelLock?> criacoes = [];

  /// Overrides enviados à Runs API.
  final List<String?> modelosRuns = [];

  @override
  Stream<RunEvent> runEvents(String runId) {
    final streamIndex = int.tryParse(runId.replaceFirst('run-', ''));
    if (streamIndex != null &&
        streamIndex > 0 &&
        streamIndex <= _controlledStreams.length) {
      return _controlledStreams[streamIndex - 1];
    }
    return _defaultRunEvents();
  }

  Stream<RunEvent> _defaultRunEvents() async* {
    yield const RunEvent.toolProgress(
      ToolCall(
        name: 'read_file',
        arg: 'arquivo.md',
        status: ToolStatus.running,
      ),
    );
    if (emitsToolCompletion) {
      yield const RunEvent.toolProgress(
        ToolCall(name: 'read_file', arg: 'arquivo.md', status: ToolStatus.done),
      );
    }
    yield RunEvent.delta(answer);
    yield RunEvent.completed(output: answer);
  }

  @override
  Future<Run> getRun(String runId) async {
    if (_runSnapshotResults.isNotEmpty) {
      final snapshotIndex = _nextRunSnapshot < _runSnapshotResults.length
          ? _nextRunSnapshot++
          : _runSnapshotResults.length - 1;
      final snapshot = _runSnapshotResults[snapshotIndex];
      if (snapshot is! Run) throw snapshot;
      return snapshot.copyWith(runId: runId);
    }
    return Run(runId: runId, status: RunStatus.completed, output: answer);
  }

  @override
  Future<Run> stopRun(String runId) async =>
      Run(runId: runId, status: RunStatus.stopping);
}
