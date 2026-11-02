import 'dart:async';
import 'dart:typed_data';

import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/gateway_inflight.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/domain/models/platform_pairing.dart';
import 'package:hermes_mobile/domain/models/server_health.dart';
import 'package:hermes_mobile/domain/models/server_tools.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/session_search.dart';
import 'package:hermes_mobile/domain/models/usage_summary.dart';
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

  final Map<String, Uint8List> midias = {};
  final List<String> midiasLidas = [];

  @override
  Future<Uint8List> agentMedia(String path) async {
    midiasLidas.add(path);
    final bytes = midias[path];
    if (bytes == null) {
      throw const GatewayOperationException(
        'A imagem não está mais no servidor.',
        httpStatus: 404,
      );
    }
    return bytes;
  }

  /// Estados devolvidos em sequência por [gatewayRuntime]; o último se repete.
  List<GatewayRuntime> estados = const [
    GatewayRuntime(running: true, state: 'running', activeSessions: 1),
  ];
  HostStats maquina = const HostStats(hostname: 'servidor', cpuPercent: 12);
  List<String> linhasDeLog = const [];
  final List<({GatewayLogFile file, GatewayLogLevel level, String? search})>
  consultasDeLog = [];
  int reinicios = 0;
  Object? falhaEmEstado;

  @override
  Future<GatewayRuntime> gatewayRuntime() async {
    final falha = falhaEmEstado;
    if (falha != null) throw falha;
    final atual = estados.first;
    if (estados.length > 1) estados = estados.sublist(1);
    return atual;
  }

  @override
  Future<HostStats> hostStats() async => maquina;

  @override
  Future<List<String>> logs({
    required GatewayLogFile file,
    GatewayLogLevel level = GatewayLogLevel.all,
    String? search,
    int lines = 200,
  }) async {
    consultasDeLog.add((file: file, level: level, search: search));
    return linhasDeLog;
  }

  @override
  Future<void> restartGateway() async => reinicios++;

  @override
  Future<GatewayActionStatus> restartStatus() async =>
      const GatewayActionStatus(exitCode: 0);

  UsageSummary Function(int days) usoPorPeriodo = (days) =>
      UsageSummary(periodDays: days);
  final List<int> periodosPedidos = [];

  @override
  Future<UsageSummary> usage({required int days}) async {
    periodosPedidos.add(days);
    return usoPorPeriodo(days);
  }

  List<SessionSearchHit> resultadosDeBusca = const [];
  final List<String> buscas = [];

  @override
  Future<List<SessionSearchHit>> searchSessions(
    String query, {
    int limit = 20,
  }) async {
    buscas.add(query);
    return resultadosDeBusca;
  }

  List<ToolsetSetting> toolsets = const [];
  List<McpServerSetting> servidoresMcp = const [];
  McpProbe sondaMcp = const McpProbe(ok: true, tools: ['buscar']);
  final List<String> alternanciasDeFerramentas = [];
  Object? falhaAoAlternar;

  @override
  Future<List<ToolsetSetting>> toolsetSettings() async => toolsets;

  @override
  Future<void> setToolsetEnabled(String name, {required bool enabled}) async {
    final falha = falhaAoAlternar;
    if (falha != null) throw falha;
    alternanciasDeFerramentas.add('toolset:$name:$enabled');
    toolsets = [
      for (final t in toolsets)
        t.name == name ? t.copyWith(enabled: enabled) : t,
    ];
  }

  @override
  Future<List<McpServerSetting>> mcpServers() async => servidoresMcp;

  @override
  Future<void> setMcpServerEnabled(String name, {required bool enabled}) async {
    final falha = falhaAoAlternar;
    if (falha != null) throw falha;
    alternanciasDeFerramentas.add('mcp:$name:$enabled');
    servidoresMcp = [
      for (final s in servidoresMcp)
        s.name == name ? s.copyWith(enabled: enabled) : s,
    ];
  }

  @override
  Future<McpProbe> testMcpServer(String name) async => sondaMcp;

  List<PairingRequest> pedidosDeAcesso = const [];
  List<PairedUser> acessosAprovados = const [];
  final List<String> acoesDeAcesso = [];

  @override
  Future<PairingState> pairing() async =>
      (pending: pedidosDeAcesso, approved: acessosAprovados);

  @override
  Future<void> approvePairing(String platform, String requestId) async {
    acoesDeAcesso.add('approve:$platform:$requestId');
    final pedido = pedidosDeAcesso.firstWhere((p) => p.requestId == requestId);
    pedidosDeAcesso = [
      for (final p in pedidosDeAcesso)
        if (p.requestId != requestId) p,
    ];
    acessosAprovados = [
      ...acessosAprovados,
      PairedUser(
        platform: platform,
        userId: pedido.userId,
        userName: pedido.userName,
      ),
    ];
  }

  @override
  Future<void> revokePairing(String platform, String userId) async {
    acoesDeAcesso.add('revoke:$platform:$userId');
    acessosAprovados = [
      for (final u in acessosAprovados)
        if (u.userId != userId) u,
    ];
  }

  @override
  Future<int> clearPendingPairings() async {
    acoesDeAcesso.add('clear');
    final total = pedidosDeAcesso.length;
    pedidosDeAcesso = const [];
    return total;
  }

  final List<String> falas = [];
  Object? falhaAoFalar;
  Completer<void>? sinteseSegura;

  @override
  Future<SpokenAudio> speak(String text) async {
    falas.add(text);
    await sinteseSegura?.future;
    final falha = falhaAoFalar;
    if (falha != null) throw falha;
    return (bytes: Uint8List.fromList([1, 2, 3]), mimeType: 'audio/mpeg');
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
