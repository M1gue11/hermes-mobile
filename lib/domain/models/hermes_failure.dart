/// Falha de conversa com o Hermes, já traduzida para algo que dá para ler.
///
/// Existe porque a tela mostrava `'$error'` direto: uma `DioException` inteira,
/// com tipo, caminho e mensagem interna, no lugar onde deveria haver a causa e
/// o que fazer. Além de ilegível, string crua de exceção é um vazamento lento:
/// hoje é o caminho da rota, amanhã é o que alguém puser no `toString`.
///
/// A tradução mora no **adapter**, como no `ModelLockException` e no
/// `ApprovalException`, então `lib/features/` continua sem conhecer `dio`.
enum HermesFailureKind {
  /// Não saiu do aparelho: sem rede, DNS, host fora da tailnet.
  semRede,

  /// Saiu, mas ninguém respondeu a tempo.
  tempoEsgotado,

  /// Chave ausente, errada ou expirada (401).
  naoAutenticado,

  /// Autenticado, mas sem direito àquilo (403).
  semPermissao,

  /// Rota ou recurso que não existe (404).
  naoEncontrado,

  /// O gateway está de pé mas recusou por estado próprio (409, 429, 503).
  gatewayIndisponivel,

  /// O servidor quebrou (5xx).
  servidorFalhou,

  /// Respondeu, mas com algo que o app não sabe ler.
  respostaInesperada,

  /// Cancelado pelo próprio app, ao trocar de conversa por exemplo.
  cancelado,
}

class HermesFailure implements Exception {
  const HermesFailure(this.kind, {this.statusCode, this.code, this.serverMessage});

  final HermesFailureKind kind;
  final int? statusCode;

  /// Código público do envelope de erro, tipo `gateway_auth_failed`. Útil para
  /// o dono do aparelho relatar o problema sem precisar de log.
  final String? code;

  /// Mensagem que o próprio servidor devolveu no envelope público. Não é
  /// `toString` de exceção: é texto que o Hermes escreveu para ser lido.
  final String? serverMessage;

  /// Causa, numa linha.
  String get title => switch (kind) {
        HermesFailureKind.semRede => 'Sem alcance ao Hermes',
        HermesFailureKind.tempoEsgotado => 'O Hermes demorou demais',
        HermesFailureKind.naoAutenticado => 'Chave recusada',
        HermesFailureKind.semPermissao => 'Acesso negado',
        HermesFailureKind.naoEncontrado => 'Não encontrado',
        HermesFailureKind.gatewayIndisponivel => 'O gateway não pôde atender',
        HermesFailureKind.servidorFalhou => 'O Hermes falhou',
        HermesFailureKind.respostaInesperada => 'Resposta inesperada',
        HermesFailureKind.cancelado => 'Pedido cancelado',
      };

  /// O que fazer. Sem isto o estado de erro só dá a má notícia.
  String get hint => switch (kind) {
        HermesFailureKind.semRede =>
          'Confira se o aparelho está na tailnet e se o endereço em Conexão está certo.',
        HermesFailureKind.tempoEsgotado =>
          'Pode ser rede lenta ou o gateway ocupado. Tente de novo.',
        HermesFailureKind.naoAutenticado =>
          'Abra Conexão e informe a chave de novo.',
        HermesFailureKind.semPermissao =>
          'Esta chave não tem direito a esta operação.',
        HermesFailureKind.naoEncontrado =>
          'Isto pode ter sido apagado por outro cliente.',
        HermesFailureKind.gatewayIndisponivel =>
          'O gateway está de pé, mas recusou agora. Tente em instantes.',
        HermesFailureKind.servidorFalhou =>
          'O erro é do lado do Hermes. Vale olhar o log do servidor.',
        HermesFailureKind.respostaInesperada =>
          'O Hermes respondeu num formato que este app não sabe ler.',
        HermesFailureKind.cancelado => 'Nada foi perdido.',
      };

  /// Tentar de novo só é oferecido quando pode dar certo sem o usuário mudar
  /// nada. Botão de retry num 401 é promessa falsa: sem chave nova, o próximo
  /// toque falha igual.
  bool get retryable => switch (kind) {
        HermesFailureKind.semRede => true,
        HermesFailureKind.tempoEsgotado => true,
        HermesFailureKind.gatewayIndisponivel => true,
        HermesFailureKind.servidorFalhou => true,
        HermesFailureKind.respostaInesperada => true,
        HermesFailureKind.naoAutenticado => false,
        HermesFailureKind.semPermissao => false,
        HermesFailureKind.naoEncontrado => false,
        HermesFailureKind.cancelado => false,
      };

  /// Linha técnica curta, para o dono do aparelho conseguir relatar. Só o que é
  /// público: status e código do envelope. Nunca caminho, host ou cabeçalho.
  String? get reference {
    final partes = [
      if (statusCode != null) 'HTTP $statusCode',
      if (code != null && code!.isNotEmpty) code!,
    ];
    return partes.isEmpty ? null : partes.join(' · ');
  }

  @override
  String toString() => reference == null ? title : '$title ($reference)';
}

/// Traduz o status HTTP na causa. Tabela única, para a lista, o chat e o
/// seletor de modelos não divergirem no que chamam de erro.
HermesFailureKind hermesFailureKindFromStatus(int? statusCode) {
  if (statusCode == null) return HermesFailureKind.respostaInesperada;
  if (statusCode == 401) return HermesFailureKind.naoAutenticado;
  if (statusCode == 403) return HermesFailureKind.semPermissao;
  if (statusCode == 404) return HermesFailureKind.naoEncontrado;
  if (statusCode == 408) return HermesFailureKind.tempoEsgotado;
  if (statusCode == 409 || statusCode == 429 || statusCode == 503) {
    return HermesFailureKind.gatewayIndisponivel;
  }
  if (statusCode >= 500) return HermesFailureKind.servidorFalhou;
  if (statusCode >= 400) return HermesFailureKind.respostaInesperada;
  return HermesFailureKind.respostaInesperada;
}

/// Última linha de defesa da tela: qualquer erro vira uma falha legível.
///
/// O que chega aqui já deveria ser `HermesFailure`, porque o adapter traduz.
/// Mas engolir um erro inesperado e mostrar tela em branco é pior do que dizer
/// que houve um erro que o app não reconheceu, então o caso desconhecido tem
/// resposta própria em vez de `toString`.
HermesFailure hermesFailureFrom(Object? error) {
  if (error is HermesFailure) return error;
  return const HermesFailure(HermesFailureKind.respostaInesperada);
}
