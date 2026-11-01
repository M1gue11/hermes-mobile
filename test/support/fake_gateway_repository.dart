import 'dart:async';

import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/gateway_inflight.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';

class FakeGatewayRepository implements GatewayRepository {
  FakeGatewayRepository({
    this.paired = true,
    this.authenticateHandler,
    List<FakeGatewayLiveTurn>? turns,
    Map<String, List<SessionMessage>>? histories,
  }) : turns = [...?turns],
       histories = {...?histories};

  bool paired;
  final Future<void> Function({
    required String baseUrl,
    required String username,
    required String password,
  })?
  authenticateHandler;
  final List<({String baseUrl, String username, String password})>
  authentications = [];
  final List<FakeGatewayLiveTurn> turns;
  final Map<String, List<SessionMessage>> histories;
  final List<String> openedSessionIds = [];
  final List<String> historySessionIds = [];

  @override
  Future<bool> hasSession() async => paired;

  @override
  Future<List<SessionMessage>> conversationHistory({
    required String storedSessionId,
  }) async {
    historySessionIds.add(storedSessionId);
    return List<SessionMessage>.unmodifiable(
      histories[storedSessionId] ?? const [],
    );
  }

  @override
  Future<GatewayLiveTurn> openLiveTurn({
    required String storedSessionId,
    GatewayReplayCursor? after,
    bool recover = false,
  }) async {
    openedSessionIds.add(storedSessionId);
    if (turns.isEmpty) {
      throw const GatewayOperationException('Sem turno fake disponível.');
    }
    return turns.removeAt(0);
  }

  @override
  Future<List<GatewayProbeStep>> probeGateway({
    String? storedSessionId,
  }) async => const <GatewayProbeStep>[];

  @override
  Future<void> authenticate({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    authentications.add((
      baseUrl: baseUrl,
      username: username,
      password: password,
    ));
    final handler = authenticateHandler;
    if (handler != null) {
      await handler(baseUrl: baseUrl, username: username, password: password);
    }
    paired = true;
  }

  @override
  Future<ComposerAttachment> attachFile({
    required String storedSessionId,
    required ComposerAttachment attachment,
  }) async => attachment;

  @override
  Future<String> transcribeAudio(ComposerAttachment attachment) async => '';

  List<HermesSkill> catalogo = const [];
  final Map<String, String> conteudos = {};
  final List<({String name, String content})> gravacoes = [];
  final List<({String name, bool enabled})> alternancias = [];
  Object? falhaAoGravar;

  @override
  Future<List<HermesSkill>> skills() async => catalogo;

  @override
  Future<String> skillContent(String name) async {
    final content = conteudos[name];
    if (content == null) {
      throw GatewayOperationException("Skill '$name' not found.");
    }
    return content;
  }

  @override
  Future<void> saveSkillContent(String name, String content) async {
    final falha = falhaAoGravar;
    if (falha != null) throw falha;
    gravacoes.add((name: name, content: content));
    conteudos[name] = content;
  }

  @override
  Future<void> setSkillEnabled(String name, {required bool enabled}) async {
    alternancias.add((name: name, enabled: enabled));
    catalogo = [
      for (final skill in catalogo)
        skill.name == name ? skill.copyWith(enabled: enabled) : skill,
    ];
  }
}

class FakeGatewayLiveTurn implements GatewayLiveTurn {
  FakeGatewayLiveTurn({
    required this.storedSessionId,
    required this.liveSessionId,
    this.running = true,
    this.initialHistory = const [],
    this.inflight,
    this.cursor,
    this.recoveryMode = GatewayRecoveryMode.snapshot,
    this.submitError,
  });

  final _events = StreamController<RunEvent>.broadcast(sync: true);
  final List<String> submitted = [];
  final List<String> steered = [];
  final List<ApprovalChoice> approvals = [];
  final List<({String requestId, String? questionId, Object answer})>
  clarifications = [];
  Object? clarificationError;
  List<String>? clarificationRemaining;
  bool clarificationExpired = false;
  Map<String, Object?>? serverAnswers;
  final Object? submitError;
  bool interrupted = false;
  bool closed = false;

  @override
  final String storedSessionId;

  @override
  final String liveSessionId;

  @override
  String get turnId => 'gateway:$liveSessionId';

  @override
  final bool running;

  @override
  final List<SessionMessage> initialHistory;

  @override
  final GatewayInflight? inflight;

  @override
  final GatewayReplayCursor? cursor;

  @override
  final GatewayRecoveryMode recoveryMode;

  @override
  Stream<RunEvent> get events => _events.stream;

  void add(RunEvent event) => _events.add(event);

  void addError(Object error) => _events.addError(error);

  Future<void> finishStream() => _events.close();

  @override
  Future<GatewayPromptReceipt> submit(String text) async {
    final error = submitError;
    if (error != null) throw error;
    submitted.add(text);
    return const GatewayPromptReceipt();
  }

  @override
  Future<void> steer(String text) async => steered.add(text);

  @override
  Future<void> interrupt() async => interrupted = true;

  @override
  Future<void> respondToApproval(
    ApprovalChoice choice, {
    String? requestId,
  }) async => approvals.add(choice);

  @override
  Future<ClarifyResponse> lockClarification({
    required String requestId,
    required String questionId,
    required Object answer,
  }) async {
    final error = clarificationError;
    if (error != null) throw error;
    clarifications.add((
      requestId: requestId,
      questionId: questionId,
      answer: answer,
    ));
    serverAnswers = {...?serverAnswers, questionId: answer};
    return ClarifyResponse(
      remaining: clarificationRemaining,
      expired: clarificationExpired,
    );
  }

  @override
  Future<List<SessionMessage>> refreshHistory() async => initialHistory;

  @override
  Future<void> close() async {
    closed = true;
    await Future<void>.delayed(Duration.zero);
    if (!_events.isClosed) await _events.close();
  }
}
