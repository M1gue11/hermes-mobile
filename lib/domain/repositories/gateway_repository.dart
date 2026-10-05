import '../models/approval_request.dart';
import '../models/composer_attachment.dart';
import '../models/run_event.dart';
import '../models/session_message.dart';

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
  'prompt.submit',
  'session.steer',
  'session.interrupt',
  'clarify.lock',
  'approval.respond',
  'client.capabilities',
  // Autorizado explicitamente pelo usuário em 2026-08-07 para anexos móveis.
  'file.attach',
};

/// Eventos conhecidos no snapshot 0.18.2 e revalidados nominalmente em 0.19.0.
/// Um evento novo continua chegando como `RunEvent.unknown`; a allowlist impede
/// que um nome desconhecido ganhe semântica de UI por acidente.
const knownGatewayEvents = <String>{
  'gateway.ready',
  'skin.changed',
  'session.info',
  'message.start',
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

  /// Carrega o histórico durável pelo Dashboard sem adotar a sessão como um
  /// turno ao vivo. É a fonte autoritativa para conversas que usaram o TUI.
  Future<List<SessionMessage>> conversationHistory({
    required String storedSessionId,
  });

  /// Abre um socket novo, espera `gateway.ready` e retoma a sessão durável.
  /// Nenhum prompt é enviado por esta operação, portanto ainda é seguro cair
  /// para Runs se ela falhar.
  Future<GatewayLiveTurn> openLiveTurn({required String storedSessionId});

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
  List<SessionMessage> get initialHistory;
  Stream<RunEvent> get events;

  Future<void> submit(String text);
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

final class GatewayOperationException implements Exception {
  const GatewayOperationException(
    this.message, {
    this.method,
    this.code,
    this.detail,
  });

  /// Texto destinado à pessoa. Nunca carrega exceção de servidor.
  final String message;

  /// Método JSON-RPC que falhou, quando a falha veio do gateway.
  final String? method;

  /// Código JSON-RPC devolvido pelo gateway.
  final int? code;

  /// Texto cru do gateway. Existe para diagnóstico e log, não para a interface.
  final String? detail;

  @override
  String toString() => [
    'GatewayOperationException: $message',
    if (method != null) 'method=$method',
    if (code != null) 'code=$code',
    if (detail != null) 'detail=$detail',
  ].join(' ');
}

final class GatewayCredentialsRejected extends GatewayOperationException {
  const GatewayCredentialsRejected(super.message);
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
    _ => 'O Hermes não conseguiu ${gatewayActionLabel(method)}. Tente de novo.',
  },
  method: method,
  code: code,
  detail: message,
);

/// Nome da ação em português para compor a mensagem de falha.
String gatewayActionLabel(String method) => switch (method) {
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
