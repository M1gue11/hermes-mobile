import 'dart:typed_data';

import '../models/agent_file.dart';
import '../models/approval_request.dart';
import '../models/gateway_command.dart';
import '../models/composer_attachment.dart';
import '../models/gateway_inflight.dart';
import '../models/gateway_recovery.dart';
import '../models/hermes_skill.dart';
import '../models/platform_pairing.dart';
import '../models/push_device.dart';
import '../models/run_event.dart';
import '../models/server_health.dart';
import '../models/server_tools.dart';
import '../models/session_search.dart';
import '../models/usage_summary.dart';
import '../models/session_message.dart';

export '../models/gateway_recovery.dart';

/// Áudio sintetizado pelo servidor, pronto para tocar.
typedef SpokenAudio = ({Uint8List bytes, String mimeType});

class ClarifyResponse {
  const ClarifyResponse({this.remaining, this.expired = false});

  /// Só é retornado para batch; `null` preserva a semântica single.
  final List<String>? remaining;
  final bool expired;
}

const allowedGatewayMethods = <String>{
  // Keepalive autorizado pelo contrato WebSocket quando `gateway.ready`
  // anuncia `heartbeat: true`. Backends antigos não recebem esta chamada.
  'gateway.ping',
  'session.create',
  'session.resume',
  'session.list',
  'session.most_recent',
  'session.history',
  'session.events.since',
  'prompt.submit',
  'session.steer',
  'session.interrupt',
  'clarify.lock',
  'approval.respond',
  'client.capabilities',
  // Autorizado explicitamente pelo usuário em 2026-08-07 para anexos móveis.
  'file.attach',
  // A80: authorized command discovery/execution; contract verified against
  // the user's Hermes Agent repository, tag v0.22.5.
  'commands.catalog',
  'complete.slash',
  'slash.exec',
  'command.dispatch',
};

/// Eventos conhecidos no snapshot 0.18.2 e revalidados nominalmente em 0.19.0.
/// Um evento novo continua chegando como `RunEvent.unknown`; a allowlist impede
/// que um nome desconhecido ganhe semântica de UI por acidente.
const knownGatewayEvents = <String>{
  'gateway.ready',
  'skin.changed',
  'session.info',
  'message.start',
  'message.interim',
  'message.delta',
  'message.complete',
  'thinking.delta',
  'reasoning.delta',
  'reasoning.available',
  'status.update',
  'notification.show',
  'notification.clear',
  'tool.start',
  'tool.generating',
  // `tool.progress` saiu daqui em 2026-08-15: o nome vinha do snapshot 0.18.2,
  // mas o gateway nunca o emite. `_on_tool_progress` desdobra em
  // `tool.output_risk`, `reasoning.available` e `moa.*`. Se algum dia voltar,
  // chega como `RunEvent.unknown` e é decidido de novo, não em silêncio.
  'tool.complete',
  'tool.output_risk',
  'session.reclaimed',
  'approval.cancelled',
  'todo.updated',
  'approval.request',
  'sudo.request',
  'sudo.expire',
  'secret.request',
  'secret.expire',
  'request.cancel',
  'background.complete',
  'billing.step_up.verification',
  'review.summary',
  'browser.progress',
  'voice.status',
  'voice.transcript',
  'subagent.spawn_requested',
  'subagent.start',
  'subagent.thinking',
  'subagent.tool',
  'subagent.progress',
  'subagent.complete',
  'gateway.stderr',
  'gateway.protocol_error',
  'gateway.start_timeout',
};

abstract interface class GatewayRepository {
  Future<bool> hasSession();

  Future<void> authenticate({
    required String baseUrl,
    required String username,
    required String password,
  });

  /// Prepara um anexo e devolve a referência `@file:` usada no prompt.
  ///
  /// Chamadas seguidas para a mesma conversa compartilham uma única conexão
  /// retomada, que segue aberta até o [openLiveTurn] seguinte consumi-la.
  Future<ComposerAttachment> attachFile({
    required String storedSessionId,
    required ComposerAttachment attachment,
  });

  Future<String> transcribeAudio(ComposerAttachment attachment);

  /// Catálogo de skills do perfil, por `GET /api/skills` do Dashboard.
  /// Inclui as desativadas, com [HermesSkill.enabled] preenchido.
  Future<List<HermesSkill>> skills();

  /// Texto integral do `SKILL.md`.
  Future<String> skillContent(String name);

  /// Reescreve o `SKILL.md` inteiro. Quando o Dashboard recusa o conteúdo, a
  /// causa dele vem em [GatewayOperationException.message].
  Future<void> saveSkillContent(String name, String content);

  /// Ativa ou desativa a skill no perfil atual do Dashboard.
  Future<void> setSkillEnabled(String name, {required bool enabled});

  /// Bytes de uma imagem que o agente entregou por `MEDIA:<caminho>`, lidos
  /// por `GET /api/media`. O servidor só serve imagens das pastas de mídia do
  /// Hermes (`images`, `screenshots`, `cache`) e até 25 MB; a recusa vem como
  /// [GatewayOperationException] com a causa em português.
  Future<Uint8List> agentMedia(String path);

  /// Download autenticado para um destino privado do app. Cancelar interrompe
  /// a rede e o chamador descarta o arquivo parcial.
  Future<AgentFileInfo> downloadAgentFile({
    required String path,
    required String destination,
    required void Function(int received, int? total) onProgress,
    required Future<void> cancelled,
  });

  /// Estado do processo do gateway, por `GET /api/status`.
  Future<GatewayRuntime> gatewayRuntime();

  /// Medidas da máquina do servidor, por `GET /api/system/stats`.
  Future<HostStats> hostStats();

  /// Fim do arquivo de log, em ordem cronológica (a mais nova por último).
  Future<List<String>> logs({
    required GatewayLogFile file,
    GatewayLogLevel level = GatewayLogLevel.all,
    String? search,
    int lines = 200,
  });

  /// Pede `hermes gateway restart --interrupt`: interrompe turnos em
  /// andamento e derruba o API Server até o gateway voltar.
  Future<void> restartGateway();

  /// Andamento do último reinício pedido.
  Future<GatewayActionStatus> restartStatus();

  /// Tokens e custo dos últimos [days] dias, por `GET /api/analytics/usage`.
  Future<UsageSummary> usage({required int days});

  /// Busca no conteúdo, no título e no id de todas as conversas, por
  /// `GET /api/sessions/search`. Uma conversa compactada aparece uma vez só,
  /// já apontando para a sessão mais recente da linhagem.
  Future<List<SessionSearchHit>> searchSessions(String query, {int limit = 20});

  /// Toolsets configuráveis do perfil, por `GET /api/tools/toolsets`.
  Future<List<ToolsetSetting>> toolsetSettings();

  Future<void> setToolsetEnabled(String name, {required bool enabled});

  /// Servidores MCP do perfil, por `GET /api/mcp/servers`.
  Future<List<McpServerSetting>> mcpServers();

  /// Grava `enabled` no `config.yaml`; vale na próxima sessão. Servidor de
  /// plugin é recusado com a causa em português.
  Future<void> setMcpServerEnabled(String name, {required bool enabled});

  /// Conecta, lista as ferramentas e desconecta. A falha de conexão volta
  /// como [McpProbe.ok] falso, não como exceção.
  Future<McpProbe> testMcpServer(String name);

  /// Pedidos de acesso pendentes e pessoas aprovadas em plataformas de
  /// mensagem, por `GET /api/pairing`.
  Future<PairingState> pairing();

  /// Aprova pelo id do pedido; a pessoa passa a conversar com o agente.
  Future<void> approvePairing(String platform, String requestId);

  Future<void> revokePairing(String platform, String userId);

  /// Descarta todos os pedidos pendentes e devolve quantos eram.
  Future<int> clearPendingPairings();

  /// Sintetiza [text] com o TTS configurado no perfil, por
  /// `POST /api/audio/speak`.
  Future<SpokenAudio> speak(String text);

  /// Aparelhos do plugin `mobile-push`, por
  /// `GET /api/plugins/mobile-push/devices`. Sem o plugin instalado no
  /// servidor, lança [PushPluginMissing].
  Future<PushServerState> pushDevices();

  /// Registra ou renova este aparelho. Endpoint recusado pelo servidor vem
  /// como [GatewayOperationException] com a causa em português.
  Future<void> registerPushDevice(PushRegistration registration);

  Future<void> removePushDevice(String deviceId);

  /// Pede ao servidor um push de teste para este aparelho.
  Future<PushTestResult> testPushDevice(String deviceId);

  /// Carrega o histórico durável pelo Dashboard sem adotar a sessão como um
  /// turno ao vivo. É a fonte autoritativa para conversas que usaram o TUI.
  Future<List<SessionMessage>> conversationHistory({
    required String storedSessionId,
  });

  /// Abre um socket novo, espera `gateway.ready` e retoma a sessão durável.
  /// Nenhum prompt é enviado por esta operação, portanto ainda é seguro cair
  /// para Runs se ela falhar.
  Future<GatewayLiveTurn> openLiveTurn({
    required String storedSessionId,
    GatewayReplayCursor? after,
    bool recover = false,
  });

  /// Diagnóstico: chama métodos da allowlist em sequência num socket só e
  /// devolve o desfecho de cada um.
  ///
  /// Existe porque `session.resume` falhar sozinho e o gateway inteiro estar
  /// morto produzem exatamente o mesmo sintoma no app: queda silenciosa para a
  /// Runs API. Se `session.list` responde e `session.resume` recusa, o
  /// `SessionDB` está vivo e o problema é do resume; se os dois recusam com o
  /// mesmo erro, a conexão do banco morreu no processo do gateway.
  ///
  /// Nenhum prompt é submetido. `session.resume` entra por último, com os
  /// mesmos parâmetros do envio real, porque reproduzi-lo é o objetivo.
  Future<List<GatewayProbeStep>> probeGateway({String? storedSessionId});
}

/// Resultado de um passo da sonda, já redigido para leitura e cópia.
class GatewayProbeStep {
  const GatewayProbeStep({
    required this.method,
    required this.ok,
    required this.detail,
  });

  final String method;
  final bool ok;

  /// Forma da resposta ou código/mensagem da recusa. Nunca conteúdo de conversa.
  final String detail;

  @override
  String toString() => '${ok ? "ok" : "ERRO"} $method  $detail';
}

/// Sessão live já autenticada. [liveSessionId] é o único identificador aceito
/// pelos métodos RPC; [storedSessionId] é usado apenas em reconexões futuras.
abstract interface class GatewayLiveTurn {
  String get storedSessionId;
  String get liveSessionId;
  String get turnId;
  bool get running;
  GatewayInflight? get inflight;
  GatewayReplayCursor? get cursor;
  GatewayRecoveryMode get recoveryMode;
  List<SessionMessage> get initialHistory;
  Stream<RunEvent> get events;

  Future<GatewayPromptReceipt> submit(String text);
  Future<GatewayCommandCatalog> commandCatalog();
  Future<GatewaySlashCompletions> completeSlash(String text);
  Future<GatewayCommandResult> executeCommand(String command);
  Future<void> steer(String text);
  Future<void> interrupt();
  Future<void> respondToApproval(ApprovalChoice choice, {String? requestId});
  Future<ClarifyResponse> lockClarification({
    required String requestId,
    required String questionId,
    required Object answer,
  });
  Future<List<SessionMessage>> refreshHistory();
  Future<void> close();
}

final class GatewayAuthenticationRequired implements Exception {
  const GatewayAuthenticationRequired([
    this.message = 'Entre no Dashboard para enviar anexos.',
  ]);

  final String message;
}

class GatewayPromptReceipt {
  const GatewayPromptReceipt({this.status = 'streaming', this.userRowId});
  final String status;
  final int? userRowId;
}

/// The frame was handed to the socket but no authoritative reply arrived.
/// Recovery must inspect the remote turn rather than treating this as refusal.
final class GatewaySubmissionUncertain extends GatewayOperationException {
  const GatewaySubmissionUncertain()
    : super(
        'A confirmação do envio não chegou. Retomando a conversa…',
        method: 'prompt.submit',
      );
}

final class GatewayRequestNotSent extends GatewayOperationException {
  const GatewayRequestNotSent({required String method})
    : super('O canal do gateway foi encerrado antes do envio.', method: method);
}

final class GatewayOperationException implements Exception {
  const GatewayOperationException(
    this.message, {
    this.method,
    this.code,
    this.detail,
    this.httpStatus,
  });

  /// Texto destinado à pessoa. Nunca carrega exceção de servidor.
  final String message;

  /// Método JSON-RPC que falhou, quando a falha veio do gateway.
  final String? method;

  /// Código JSON-RPC devolvido pelo gateway.
  final int? code;

  /// Texto cru do gateway. Existe para diagnóstico e log, não para a interface.
  final String? detail;

  /// Status da resposta HTTP do Dashboard, quando a falha veio dele.
  final int? httpStatus;

  @override
  String toString() => [
    'GatewayOperationException: $message',
    if (method != null) 'method=$method',
    if (code != null) 'code=$code',
    if (httpStatus != null) 'status=$httpStatus',
    if (detail != null) 'detail=$detail',
  ].join(' ');
}

final class GatewayCredentialsRejected extends GatewayOperationException {
  const GatewayCredentialsRejected(super.message);
}

/// O Dashboard respondeu 404 nas rotas do `mobile-push`: o plugin não está
/// instalado, não está ativo ou o Dashboard não foi reiniciado depois.
final class PushPluginMissing extends GatewayOperationException {
  const PushPluginMissing()
    : super(
        'O plugin mobile-push não está ativo neste Hermes.',
        httpStatus: 404,
      );
}

/// Traduz um erro JSON-RPC do gateway em algo que a pessoa possa agir.
///
/// A mensagem do servidor é diagnóstico, não texto de produto: `-32000` é o
/// envelope genérico do gateway e carrega a exceção Python crua do handler.
/// Ela fica em [GatewayOperationException.detail], junto do método, para que a
/// próxima ocorrência diga qual RPC falhou sem expor o interior do servidor.
GatewayOperationException gatewayRpcFailure({
  required String method,
  required int code,
  required String message,
}) => GatewayOperationException(
  switch (code) {
    4001 => 'A sessão foi encerrada no Hermes. Abra a conversa de novo.',
    4015 || -32602 =>
      'O Hermes recusou os dados enviados para ${gatewayActionLabel(method)}.',
    -32601 => 'Este Hermes não oferece ${gatewayActionLabel(method)}.',
    5032 => 'O agente do Hermes não terminou de iniciar. Tente de novo.',
    4009 => 'A conversa está ocupada. Aguarde a execução atual terminar.',
    4011 || 4018 =>
      'Este comando ou estes argumentos não estão disponíveis nesta sessão do Hermes.',
    _ => 'O Hermes não conseguiu ${gatewayActionLabel(method)}. Tente de novo.',
  },
  method: method,
  code: code,
  detail: message,
);

/// Nome da ação em português para compor a mensagem de falha.
String gatewayActionLabel(String method) => switch (method) {
  'commands.catalog' => 'listar os comandos',
  'complete.slash' => 'sugerir comandos',
  'slash.exec' || 'command.dispatch' => 'executar o comando',
  'file.attach' => 'preparar o anexo',
  'prompt.submit' => 'enviar a mensagem',
  'session.create' => 'criar a conversa',
  'session.resume' => 'retomar a conversa',
  'session.history' => 'carregar a conversa',
  'session.list' || 'session.most_recent' => 'listar as conversas',
  'session.steer' => 'orientar a resposta',
  'session.interrupt' => 'interromper a resposta',
  'approval.respond' => 'responder à aprovação',
  'clarify.lock' => 'responder ao esclarecimento',
  _ => 'concluir a operação',
};
