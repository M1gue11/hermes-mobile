import 'package:dio/dio.dart';

import '../../domain/models/hermes_failure.dart';

/// Erro público e seguro devolvido pelo API Server.
///
/// Não carrega request headers, cookies, tickets nem o corpo bruto da resposta.
class HermesApiException implements Exception {
  const HermesApiException({
    required this.statusCode,
    this.message,
    this.type,
    this.code,
  });

  final int? statusCode;
  final String? message;
  final String? type;
  final String? code;

  @override
  String toString() {
    final status = statusCode == null ? 'HTTP' : 'HTTP $statusCode';
    return message == null || message!.isEmpty ? status : '$status: $message';
  }
}

/// Traduz o erro de transporte na falha de domínio que a tela sabe mostrar.
///
/// Fica no `data/` de propósito: é aqui que `dio` é conhecido. O que sai daqui
/// é [HermesFailure], que não carrega tipo de exceção, caminho, host nem
/// cabeçalho, e que a tela consegue transformar em causa e ação. Ver A7.
HermesFailure failureFromDio(DioException error) {
  final api = error.error;
  final statusCode = api is HermesApiException ? api.statusCode : null;

  final kind = switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout =>
      HermesFailureKind.tempoEsgotado,
    // `badCertificate` entra em sem-rede de propósito: para quem está usando, o
    // efeito é o mesmo, não alcançar o Hermes, e o texto manda conferir o
    // endereço, que é onde o problema costuma estar.
    DioExceptionType.connectionError || DioExceptionType.badCertificate =>
      HermesFailureKind.semRede,
    DioExceptionType.cancel => HermesFailureKind.cancelado,
    DioExceptionType.badResponse => hermesFailureKindFromStatus(statusCode),
    DioExceptionType.unknown =>
      statusCode == null ? HermesFailureKind.semRede : hermesFailureKindFromStatus(statusCode),
  };

  return HermesFailure(
    kind,
    statusCode: statusCode,
    code: api is HermesApiException ? api.code : null,
    serverMessage: api is HermesApiException ? api.message : null,
  );
}
