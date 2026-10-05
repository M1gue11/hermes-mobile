import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/http/hermes_api_exception.dart';
import 'package:hermes_mobile/data/http/http_hermes_repository.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';

DioException dio(
  DioExceptionType type, {
  int? statusCode,
  String? code,
  String? message,
}) =>
    DioException(
      requestOptions: RequestOptions(path: '/v1/runs'),
      type: type,
      error: HermesApiException(statusCode: statusCode, code: code, message: message),
    );

void main() {
  group('tradução do transporte', () {
    test('sem alcance vira sem rede, e a dica fala da tailnet', () {
      final falha = failureFromDio(dio(DioExceptionType.connectionError));
      expect(falha.kind, HermesFailureKind.semRede);
      expect(falha.hint, contains('tailnet'));
      expect(falha.retryable, isTrue);
    });

    test('certificado inválido conta como sem alcance', () {
      // Para quem está usando, o efeito é o mesmo: não chegou ao Hermes. E a
      // dica manda conferir o endereço, que é onde o problema costuma estar.
      expect(
        failureFromDio(dio(DioExceptionType.badCertificate)).kind,
        HermesFailureKind.semRede,
      );
    });

    test('cada timeout do dio cai em tempo esgotado', () {
      for (final tipo in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(failureFromDio(dio(tipo)).kind, HermesFailureKind.tempoEsgotado);
      }
    });

    test('cancelamento não é erro para mostrar como erro', () {
      final falha = failureFromDio(dio(DioExceptionType.cancel));
      expect(falha.kind, HermesFailureKind.cancelado);
      expect(falha.retryable, isFalse);
    });

    test('status conhecidos viram causas distintas', () {
      final casos = {
        401: HermesFailureKind.naoAutenticado,
        403: HermesFailureKind.semPermissao,
        404: HermesFailureKind.naoEncontrado,
        409: HermesFailureKind.gatewayIndisponivel,
        429: HermesFailureKind.gatewayIndisponivel,
        503: HermesFailureKind.gatewayIndisponivel,
        500: HermesFailureKind.servidorFalhou,
      };
      casos.forEach((status, esperado) {
        expect(
          failureFromDio(dio(DioExceptionType.badResponse, statusCode: status)).kind,
          esperado,
          reason: 'HTTP $status',
        );
      });
    });

    test('o cliente tem timeout, senão a queda de rede vira spinner eterno', () {
      // Medido no emulador: sem `connectTimeout` o `dio` fica esperando o TCP do
      // sistema desistir, e a lista gira sem fim. Este teste fixa que existe um
      // limite, não o valor exato.
      final repository = HttpHermesRepository(apiKey: 'k');
      final options = repository.debugOptions;
      expect(options.connectTimeout, isNotNull);
      expect(options.connectTimeout! > Duration.zero, isTrue);
      expect(options.receiveTimeout, isNotNull);
      expect(options.receiveTimeout! > Duration.zero, isTrue);
    });

    test('chamada que nunca responde vira tempo esgotado, não espera eterna', () async {
      // O `connectTimeout` do `dio` não cobre tudo (a resolução de nome fica de
      // fora), então o adapter tem prazo próprio. Sem ele a lista girava sem
      // fim com a rede caída, medido no emulador.
      final repository = HttpHermesRepository(
        apiKey: 'k',
        dio: Dio()..httpClientAdapter = _AdapterQueNuncaResponde(),
        prazo: const Duration(milliseconds: 40),
      );

      await expectLater(
        repository.health(),
        throwsA(isA<HermesFailure>()
            .having((falha) => falha.kind, 'kind', HermesFailureKind.tempoEsgotado)),
      );
    });

    test('erro desconhecido sem status é falta de alcance, não erro do servidor', () {
      expect(
        failureFromDio(dio(DioExceptionType.unknown)).kind,
        HermesFailureKind.semRede,
      );
    });
  });

  group('o que a tela lê', () {
    test('retry só é oferecido quando pode dar certo sem mudar nada', () {
      // Botão de tentar de novo num 401 é promessa falsa: sem chave nova o
      // próximo toque falha igual.
      const semChave = HermesFailure(HermesFailureKind.naoAutenticado, statusCode: 401);
      const gatewayOcupado = HermesFailure(HermesFailureKind.gatewayIndisponivel, statusCode: 503);
      expect(semChave.retryable, isFalse);
      expect(gatewayOcupado.retryable, isTrue);
      expect(const HermesFailure(HermesFailureKind.semPermissao).retryable, isFalse);
      expect(const HermesFailure(HermesFailureKind.naoEncontrado).retryable, isFalse);
    });

    test('toda causa tem título e dica, sem exceção', () {
      for (final kind in HermesFailureKind.values) {
        final falha = HermesFailure(kind);
        expect(falha.title, isNotEmpty, reason: '$kind');
        expect(falha.hint, isNotEmpty, reason: '$kind');
      }
    });

    test('a referência técnica só traz o que é público', () {
      const falha = HermesFailure(
        HermesFailureKind.gatewayIndisponivel,
        statusCode: 503,
        code: 'gateway_unavailable',
        serverMessage: 'Gateway busy',
      );
      expect(falha.reference, 'HTTP 503 · gateway_unavailable');
      expect(falha.toString(), isNot(contains('/v1/')));
      expect(falha.toString(), isNot(contains('DioException')));
    });

    test('sem status nem código não inventa referência', () {
      expect(const HermesFailure(HermesFailureKind.semRede).reference, isNull);
    });

    test('erro que o app não reconhece ainda vira falha legível', () {
      // Engolir e mostrar tela em branco seria pior do que dizer que houve um
      // erro que o app não soube ler.
      final falha = hermesFailureFrom(StateError('algo interno'));
      expect(falha.kind, HermesFailureKind.respostaInesperada);
      expect(falha.title, isNotEmpty);
      expect(falha.toString(), isNot(contains('algo interno')));
    });

    test('falha que já é de domínio passa direto', () {
      const original = HermesFailure(HermesFailureKind.semRede);
      expect(hermesFailureFrom(original), same(original));
    });
  });
}

/// Adapter que aceita a chamada e nunca devolve nada, como um host inalcançável
/// cuja conexão fica pendurada.
class _AdapterQueNuncaResponde implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      Completer<ResponseBody>().future;
}
