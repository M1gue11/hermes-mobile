/// Par provider/modelo escolhido para uma conversa.
///
/// O Hermes chama isso de "browser model lock": `POST /api/sessions/{id}/model`
/// grava a escolha no banco de sessões com `confirmed: true`, então ela vale para
/// a conversa inteira e sobrevive ao fechamento do app. Um `model` mandado numa
/// run isolada continua sendo override só daquela run, sem apagar a trava.
class ModelLock {
  const ModelLock({required this.model, this.provider});

  final String model;

  /// Opcional porque o servidor aceita resolver o provider por rota ou pela forma
  /// `provider/modelo` dentro do próprio id.
  final String? provider;

  /// Corpo aceito por `_handle_session_model_lock`. `require_model_lock` não vai
  /// aqui: o handler força esse campo, mandar seria ruído.
  Map<String, Object?> toRequest() => {
        'model': model,
        if (provider != null && provider!.isNotEmpty) 'provider': provider,
      };

  factory ModelLock.fromRuntime(Map<String, dynamic> runtime) => ModelLock(
        model: runtime['model']?.toString() ?? '',
        provider: runtime['provider']?.toString(),
      );

  /// Rótulo curto para a UI: `provider/modelo` quando há provider.
  String get label =>
      provider == null || provider!.isEmpty ? model : '$provider/$model';

  @override
  bool operator ==(Object other) =>
      other is ModelLock && other.model == model && other.provider == provider;

  @override
  int get hashCode => Object.hash(model, provider);
}

/// Por que uma troca de modelo foi recusada.
///
/// O caso que importa é [naoRoteavel]: o servidor devolve `409` com
/// `model_lock_unavailable` e a mensagem "refusing silent global fallback". Ou
/// seja, ele **prefere recusar** a trocar por baixo dos panos para o modelo
/// global. A UI tem de contar isso, porque o usuário achou que escolheu algo.
enum ModelLockFailure {
  /// `409 model_lock_unavailable`: o par pedido não tem rota nesta instalação.
  naoRoteavel,

  /// `400 missing_model`.
  semModelo,

  /// `404`: a sessão não existe mais.
  sessaoInexistente,

  /// `500 model_lock_persistence_failed`, ou qualquer outra falha.
  falhaDoServidor,
}

/// Recusa de trava de modelo, já traduzida para o domínio.
///
/// O adapter HTTP converte o `DioException` nisto, para o controller e a UI não
/// precisarem conhecer `dio` nem código de status: a regra de arquitetura é que
/// `lib/features/` fale só com o port.
class ModelLockException implements Exception {
  const ModelLockException({required this.failure, required this.requested});

  final ModelLockFailure failure;
  final ModelLock requested;

  /// Texto pronto para a tela. Não carrega chave, cabeçalho nem corpo.
  String get message => modelLockFailureMessage(failure, requested);

  @override
  String toString() => 'ModelLockException(${failure.name}): $message';
}

/// Traduz o par status/código do Hermes para o motivo da recusa.
ModelLockFailure modelLockFailureFrom({int? statusCode, String? code}) {
  return switch ((statusCode, code)) {
    (_, 'model_lock_unavailable') => ModelLockFailure.naoRoteavel,
    (409, _) => ModelLockFailure.naoRoteavel,
    (_, 'missing_model') => ModelLockFailure.semModelo,
    (400, _) => ModelLockFailure.semModelo,
    (404, _) => ModelLockFailure.sessaoInexistente,
    _ => ModelLockFailure.falhaDoServidor,
  };
}

/// Mensagem para a tela. Nunca inclui chave, cabeçalho nem corpo da requisição.
String modelLockFailureMessage(ModelLockFailure failure, ModelLock pedido) {
  return switch (failure) {
    ModelLockFailure.naoRoteavel =>
      'Esta instalação não sabe rotear ${pedido.label}. O Hermes recusou em vez '
          'de trocar em silêncio para o modelo global.',
    ModelLockFailure.semModelo => 'Nenhum modelo foi informado.',
    ModelLockFailure.sessaoInexistente =>
      'Esta conversa não existe mais no servidor.',
    ModelLockFailure.falhaDoServidor =>
      'O servidor não conseguiu guardar a escolha de ${pedido.label}.',
  };
}
