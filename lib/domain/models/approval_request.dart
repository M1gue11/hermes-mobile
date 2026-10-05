/// Pedido de aprovação de execução de ferramenta, vindo do stream da run.
///
/// ## Contrato medido no Hermes `0.19.0`
///
/// O evento nasce em `_approval_notify` (`gateway/platforms/api_server.py:6149`),
/// que mescla o `approval_data` de `tools/approval.py` com o envelope da run:
///
/// ```
/// approval.request {
///   event, run_id, timestamp, choices,
///   command, description, pattern_key, pattern_keys,
///   allow_permanent, allow_session, smart_denied?
/// }
/// ```
///
/// Dois fatos de segurança que o app **depende** e não deve refazer:
///
/// - `command` e `description` chegam **já redigidos** pelo servidor, por
///   `redact_sensitive_text` e `_redact_approval_command`. O app mostra o que
///   recebeu; nunca reconstrói o comando nem tenta "melhorar" a redação.
/// - Enquanto o pedido está pendente a run fica em `waiting_for_approval` e a
///   thread do agente está **bloqueada**. Nada é aprovado por omissão: só um
///   gesto explícito resolve.
class ApprovalRequest {
  const ApprovalRequest({
    required this.runId,
    this.requestId,
    required this.command,
    this.description,
    this.patternKey,
    this.choices = const [ApprovalChoice.once, ApprovalChoice.deny],
  });

  final String runId;

  /// Id do envelope JSON-RPC quando a aprovação veio como server request.
  /// Nulo preserva o caminho legado do evento `approval.request`.
  final String? requestId;

  /// O comando que o servidor quer executar, já redigido por ele.
  final String command;

  /// Por que o servidor considerou o comando perigoso.
  final String? description;

  /// Regra que disparou a aprovação, útil para entender o `always`.
  final String? patternKey;

  /// Escolhas que **este** pedido aceita. O servidor as calcula por pedido:
  /// `smart_denied` reduz para `once`/`deny`, e sem `allow_permanent` o `always`
  /// não aparece. Oferecer botão fora desta lista é oferecer um `400`.
  final List<ApprovalChoice> choices;

  factory ApprovalRequest.fromEvent(Map<String, dynamic> json) {
    final cru = json['choices'];
    final escolhas = cru is List
        ? cru
              .map((valor) => approvalChoiceFrom(valor?.toString()))
              .whereType<ApprovalChoice>()
              .toList(growable: false)
        : const <ApprovalChoice>[];
    return ApprovalRequest(
      runId: json['run_id']?.toString() ?? '',
      requestId: json['server_request'] == true
          ? _textoOuNulo(json['request_id'])
          : null,
      command: (json['command'] ?? json['target'] ?? '').toString(),
      description: _textoOuNulo(json['description']),
      patternKey: _textoOuNulo(json['pattern_key']),
      // Sem lista utilizável, o mínimo seguro é permitir só uma vez ou recusar.
      choices: escolhas.isEmpty
          ? const [ApprovalChoice.once, ApprovalChoice.deny]
          : escolhas,
    );
  }

  static String? _textoOuNulo(Object? valor) {
    final texto = valor?.toString().trim();
    return texto == null || texto.isEmpty ? null : texto;
  }
}

/// As quatro respostas que `POST /v1/runs/{run_id}/approval` aceita em `choice`.
/// Qualquer outra devolve `400 invalid_approval_choice`.
enum ApprovalChoice {
  /// Libera só esta execução.
  once,

  /// Libera comandos deste padrão pelo resto da sessão.
  session,

  /// Libera de forma permanente, além desta sessão.
  always,

  /// Recusa. O agente recebe um BLOCKED e pode se adaptar.
  deny;

  /// Valor exato do campo `choice` no corpo da requisição.
  String get wireValue => name;
}

/// Lê a escolha do fio, aceitando os apelidos que o servidor normaliza para
/// `once` (`approve`, `approved`, `allow`).
ApprovalChoice? approvalChoiceFrom(String? valor) {
  return switch (valor?.trim().toLowerCase()) {
    'once' || 'approve' || 'approved' || 'allow' => ApprovalChoice.once,
    'session' => ApprovalChoice.session,
    'always' => ApprovalChoice.always,
    'deny' => ApprovalChoice.deny,
    _ => null,
  };
}

/// Rótulo curto do botão.
String approvalChoiceLabel(ApprovalChoice choice) {
  return switch (choice) {
    ApprovalChoice.once => 'Permitir uma vez',
    ApprovalChoice.session => 'Permitir nesta conversa',
    ApprovalChoice.always => 'Permitir sempre',
    ApprovalChoice.deny => 'Recusar',
  };
}

/// O que a escolha concede, por extenso.
///
/// `session` e `always` ampliam permissão **além desta chamada**, então a tela
/// tem de dizer isso antes do toque, não depois.
String approvalChoiceMeaning(ApprovalChoice choice) {
  return switch (choice) {
    ApprovalChoice.once => 'Vale só para esta execução.',
    ApprovalChoice.session =>
      'Libera comandos deste mesmo padrão até esta conversa terminar.',
    ApprovalChoice.always =>
      'Libera de forma permanente, também em conversas futuras.',
    ApprovalChoice.deny =>
      'A ação é bloqueada e a conversa segue sem executar o comando.',
  };
}

/// Verdadeiro para as escolhas que valem além desta execução.
bool approvalChoiceWidensAccess(ApprovalChoice choice) =>
    choice == ApprovalChoice.session || choice == ApprovalChoice.always;

/// Por que uma resposta de aprovação foi recusada pelo servidor.
enum ApprovalFailure {
  /// `400 invalid_approval_choice`.
  escolhaInvalida,

  /// `409 approval_not_active`: a run não tem sessão de aprovação aberta.
  semSessao,

  /// `409 approval_not_pending`: já foi respondido, ou a janela fechou.
  semPendencia,

  /// `404`: a run não existe mais.
  runInexistente,

  /// Qualquer outra falha.
  falhaDoServidor,
}

ApprovalFailure approvalFailureFrom({int? statusCode, String? code}) {
  return switch ((statusCode, code)) {
    (_, 'invalid_approval_choice') => ApprovalFailure.escolhaInvalida,
    (_, 'approval_not_active') => ApprovalFailure.semSessao,
    (_, 'approval_not_pending') => ApprovalFailure.semPendencia,
    (400, _) => ApprovalFailure.escolhaInvalida,
    (404, _) => ApprovalFailure.runInexistente,
    _ => ApprovalFailure.falhaDoServidor,
  };
}

String approvalFailureMessage(ApprovalFailure failure) {
  return switch (failure) {
    ApprovalFailure.escolhaInvalida =>
      'O servidor não aceitou esta resposta de aprovação.',
    ApprovalFailure.semSessao => 'Esta run não está mais esperando aprovação.',
    ApprovalFailure.semPendencia => 'Este pedido já foi respondido ou expirou.',
    ApprovalFailure.runInexistente => 'Esta run não existe mais no servidor.',
    ApprovalFailure.falhaDoServidor =>
      'O servidor não conseguiu registrar a resposta.',
  };
}

/// Recusa de resposta de aprovação, traduzida para o domínio pelo adapter.
class ApprovalException implements Exception {
  const ApprovalException(this.failure);

  final ApprovalFailure failure;

  String get message => approvalFailureMessage(failure);

  @override
  String toString() => 'ApprovalException(${failure.name}): $message';
}
