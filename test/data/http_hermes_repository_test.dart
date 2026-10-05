import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/data/http/http_hermes_repository.dart';

void main() {
  group('HttpHermesRepository', () {
    test('normaliza timestamps e preserva números num das sessões', () async {
      final repository = HttpHermesRepository(
        apiKey: 'test-key',
        dio: Dio()
          ..httpClientAdapter = _JsonAdapter({
            'object': 'list',
            'data': [
              {
                'id': 'session_1',
                'last_active': 1784217600.5,
                'started_at': '2026-07-16T00:00:00Z',
                'message_count': 1.5,
                'input_tokens': 12.25,
                'estimated_cost_usd': 0.0125,
              },
            ],
            'limit': 50,
            'offset': 0,
            'has_more': false,
          }),
      );

      final page = await repository.conversationPage();
      final conversation = page.items.single;
      expect(
        conversation.lastActive,
        DateTime.fromMillisecondsSinceEpoch(1784217600500, isUtc: true),
      );
      expect(conversation.startedAt, DateTime.utc(2026, 7, 16));
      expect(conversation.messageCount, 1.5);
      expect(conversation.inputTokens, 12.25);
      expect(conversation.estimatedCostUsd, 0.0125);
    });

    test('converte 401 OpenAI-like em exceção pública segura', () async {
      final repository = HttpHermesRepository(
        apiKey: 'very-secret-key',
        dio: Dio()
          ..httpClientAdapter = _JsonAdapter({
            'error': {
              'message': 'Invalid API key',
              'type': 'invalid_request_error',
              'code': 'invalid_api_key',
            },
          }, statusCode: 401),
      );

      // A `DioException` não sai mais do adapter: o que chega em
      // `lib/features/` é a falha de domínio, sem tipo de exceção, caminho nem
      // cabeçalho. Ver A7.
      await expectLater(
        repository.health(),
        throwsA(
          isA<HermesFailure>()
              .having(
                (falha) => falha.kind,
                'kind',
                HermesFailureKind.naoAutenticado,
              )
              .having((falha) => falha.statusCode, 'statusCode', 401)
              .having((falha) => falha.code, 'code', 'invalid_api_key')
              .having(
                (falha) => falha.serverMessage,
                'serverMessage',
                'Invalid API key',
              )
              .having((falha) => falha.retryable, 'retryable', isFalse)
              .having(
                (falha) => falha.toString(),
                'toString',
                isNot(contains('very-secret-key')),
              ),
        ),
      );
    });

    // O Hermes 0.19.0 trocou os valores do 401 de `invalid_api_key` /
    // `invalid_request_error` para `gateway_auth_failed` / `gateway_auth_error`,
    // mantendo a forma `{error: {message, type, code}}`. Medido em
    // `GET /hermes/v1/capabilities`. Este teste fixa a leitura do envelope novo
    // para que outra troca de forma quebre aqui, e não na tela do usuário.
    test('lê o envelope de erro do gateway 0.19.0', () async {
      final repository = HttpHermesRepository(
        apiKey: 'very-secret-key',
        dio: Dio()
          ..httpClientAdapter = _JsonAdapter({
            'error': {
              'message': 'Invalid gateway API key (API_SERVER_KEY)',
              'type': 'gateway_auth_error',
              'code': 'gateway_auth_failed',
            },
          }, statusCode: 401),
      );

      await expectLater(
        repository.health(),
        throwsA(
          isA<HermesFailure>()
              .having(
                (falha) => falha.kind,
                'kind',
                HermesFailureKind.naoAutenticado,
              )
              .having((falha) => falha.statusCode, 'statusCode', 401)
              .having((falha) => falha.code, 'code', 'gateway_auth_failed')
              // A tela de conexão distingue chave recusada pelo tipo da falha, e
              // não mais procurando "401" dentro do texto da exceção.
              .having((falha) => falha.reference, 'reference', contains('401'))
              .having(
                (falha) => falha.toString(),
                'toString',
                isNot(contains('very-secret-key')),
              ),
        ),
      );
    });

    // A21.1: o inventário de providers e modelos ia para `http://<host>:3000`,
    // sem chave e em cleartext, e o erro era engolido, então o app dizia que o
    // gateway não anunciava providers. A rota existe no próprio API Server, ao
    // lado de `/v1/models`, e exige a mesma chave.
    group('inventário de providers', () {
      test(
        'vai para o API Server autenticado, e não para outro serviço',
        () async {
          final adapter = _RecordingAdapter({
            'providers': [
              {
                'id': 'nous',
                'name': 'Nous',
                'models': ['hermes-4-70b'],
                'total_models': 1,
              },
            ],
            'model': 'hermes-4-70b',
            'provider': 'nous',
          });
          final repository = HttpHermesRepository(
            baseUrl: 'https://exemplo.ts.net/hermes',
            apiKey: 'test-key',
            dio: Dio(
              BaseOptions(
                baseUrl: 'https://exemplo.ts.net/hermes',
                headers: const {'Authorization': 'Bearer test-key'},
              ),
            )..httpClientAdapter = adapter,
          );

          final options = await repository.modelOptions();

          final pedido = adapter.ultimo!;
          expect(pedido.path, '/api/model/options');
          expect(pedido.baseUrl, 'https://exemplo.ts.net/hermes');
          expect(pedido.uri.scheme, 'https');
          expect(pedido.uri.port, isNot(3000));
          expect(pedido.headers['Authorization'], 'Bearer test-key');
          // A rota do API Server não lê `explicit_only`; mandar era ruído.
          expect(pedido.queryParameters, isEmpty);

          expect(options.effective?.model, 'hermes-4-70b');
          expect(options.effective?.provider, 'nous');
          expect(options.providers.single.name, 'Nous');
          expect(options.providers.single.models, ['hermes-4-70b']);
        },
      );

      test('refresh só é enviado quando pedido de propósito', () async {
        final adapter = _RecordingAdapter({'providers': <Object>[]});
        final repository = HttpHermesRepository(
          apiKey: 'test-key',
          dio: Dio()..httpClientAdapter = adapter,
        );

        await repository.modelOptions(refresh: true);
        expect(adapter.ultimo!.queryParameters, {'refresh': true});
      });

      test('falha deixa de ser silenciosa', () async {
        final repository = HttpHermesRepository(
          apiKey: 'test-key',
          dio: Dio()
            ..httpClientAdapter = _JsonAdapter({
              'error': {
                'message': 'Failed to list model options.',
                'code': 'model_options_failed',
              },
            }, statusCode: 500),
        );

        // Antes devolvia lista vazia, o que a tela lia como "o gateway não
        // anuncia providers": uma afirmação falsa sobre o servidor.
        await expectLater(
          repository.modelOptions(),
          throwsA(isA<HermesFailure>()),
        );
      });
    });

    test('criação de sessão preserva provider e modelo como par', () async {
      final adapter = _RecordingAdapter({
        'session': {
          'id': 'session-1',
          'model': 'gpt-5.6-terra',
          'provider': 'openai-codex',
        },
      });
      final repository = HttpHermesRepository(
        apiKey: 'test-key',
        dio: Dio()..httpClientAdapter = adapter,
      );

      final conversation = await repository.createConversation(
        model: 'gpt-5.6-terra',
        provider: 'openai-codex',
      );

      expect(adapter.ultimo!.data, {
        'model': 'gpt-5.6-terra',
        'provider': 'openai-codex',
      });
      expect(conversation.model, 'gpt-5.6-terra');
      expect(conversation.provider, 'openai-codex');
    });

    test('preserva respostas bem-sucedidas', () async {
      final repository = HttpHermesRepository(
        apiKey: 'test-key',
        dio: Dio()..httpClientAdapter = _JsonAdapter({'status': 'ok'}),
      );

      expect((await repository.health()).status, 'ok');
    });

    test('traduz queda depois dos headers do SSE como transporte', () async {
      final repository = HttpHermesRepository(
        apiKey: 'test-key',
        dio: Dio()..httpClientAdapter = _BrokenSseAdapter(),
      );

      await expectLater(
        repository.runEvents('run-1').toList(),
        throwsA(
          isA<HermesFailure>().having(
            (failure) => failure.kind,
            'kind',
            HermesFailureKind.semRede,
          ),
        ),
      );
    });

    test('404 ao abrir SSE é reconciliação, não evento de run falha', () async {
      final repository = HttpHermesRepository(
        apiKey: 'test-key',
        dio: Dio()
          ..httpClientAdapter = _JsonAdapter({
            'error': {'message': 'Run not found.'},
          }, statusCode: 404),
      );

      await expectLater(
        repository.runEvents('run-descartada').toList(),
        throwsA(
          isA<HermesFailure>().having(
            (failure) => failure.kind,
            'kind',
            HermesFailureKind.naoEncontrado,
          ),
        ),
      );
    });
  });
}

class _BrokenSseAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final stream = Stream<Uint8List>.multi((controller) {
      controller.add(
        Uint8List.fromList(
          utf8.encode('data: {"event":"message.delta","delta":"oi"}\n\n'),
        ),
      );
      controller.addError(StateError('socket interrompido'));
    });
    return ResponseBody(
      stream,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }
}

/// Como o `_JsonAdapter`, mas guarda o pedido: é o único jeito de provar para
/// **onde** a chamada foi, que era o defeito do A21.1.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final Object body;
  RequestOptions? ultimo;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ultimo = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body, {this.statusCode = 200});

  final Object body;
  final int statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
