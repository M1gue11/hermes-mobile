import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/gateway_repository_provider.dart';
import 'package:hermes_mobile/data/hermes_repository_provider.dart';
import 'package:hermes_mobile/data/http/http_hermes_repository.dart';
import 'package:hermes_mobile/domain/models/hermes_failure.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/features/chat/boot_provider.dart';
import 'package:hermes_mobile/features/skills/skills_provider.dart';

import '../support/fake_gateway_repository.dart';

/// Respostas do API Server 0.22.5 medidas no código do `hermes-agent`.
/// `/v1/skills` responde `500` em toda chamada por um defeito do servidor.
ProviderContainer _container({
  Map<String, int> status = const {},
  FakeGatewayRepository? gateway,
}) {
  final repo = HttpHermesRepository(
    apiKey: 'test-key',
    dio: Dio()..httpClientAdapter = _ApiServer022(status),
  );
  final container = ProviderContainer(
    // Igual ao app: falha aparece na hora, sem retry automático do Riverpod.
    retry: (_, _) => null,
    overrides: [
      hermesRepositoryProvider.overrideWithValue(repo),
      if (gateway != null) gatewayRepositoryProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('boot não depende do catálogo de skills quebrado', () async {
    final boot = await _container().read(bootStateProvider.future);

    expect(boot.online, isTrue);
    expect(boot.capabilities.features.runStop, isTrue);
    expect(boot.models.single.id, 'hermes-agent');
  });

  test(
    'falha de boot chega com a causa HTTP, não como resposta inesperada',
    () async {
      final container = _container(status: {'/v1/toolsets': 500});

      await expectLater(
        container.read(bootStateProvider.future),
        throwsA(
          isA<HermesFailure>()
              .having((f) => f.kind, 'kind', HermesFailureKind.servidorFalhou)
              .having((f) => f.statusCode, 'statusCode', 500),
        ),
      );
    },
  );

  test('skills caem para o Dashboard quando o API Server falha', () async {
    final gateway = FakeGatewayRepository()
      ..catalogo = const [
        HermesSkill(name: 'zeta', category: 'ops'),
        HermesSkill(name: 'alfa', description: 'Primeira'),
      ];
    final container = _container(gateway: gateway);

    final skills = await container.read(skillsCatalogProvider.future);

    expect(skills.map((s) => s.name), ['alfa', 'zeta']);
  });

  test('sem Dashboard, a tela mostra a falha do API Server', () async {
    final container = _container();

    await expectLater(
      container.read(skillsCatalogProvider.future),
      throwsA(
        isA<HermesFailure>().having((f) => f.statusCode, 'statusCode', 500),
      ),
    );
  });
}

class _ApiServer022 implements HttpClientAdapter {
  _ApiServer022(this.status);

  final Map<String, int> status;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final body = switch (path) {
      '/health' => {
        'status': 'ok',
        'platform': 'hermes-agent',
        'version': '0.22.5',
      },
      '/v1/capabilities' => {
        'object': 'hermes.api_server.capabilities',
        'platform': 'hermes-agent',
        'model': 'hermes-agent',
        'auth': {'type': 'bearer', 'required': true},
        'runtime': {'mode': 'server_agent', 'tool_execution': 'server'},
        'features': {
          'run_stop': true,
          'runs_idempotency': {
            'supported': true,
            'durable': true,
            'retention_seconds': 86400,
          },
          'session_continuity_header': 'X-Hermes-Session-Id',
        },
        'endpoints': {
          'health': {'method': 'GET', 'path': '/health'},
        },
      },
      '/v1/models' => {
        'object': 'list',
        'data': [
          {
            'id': 'hermes-agent',
            'object': 'model',
            'created': 1,
            'owned_by': 'hermes',
            'permission': <Object>[],
            'root': 'hermes-agent',
            'parent': null,
          },
        ],
      },
      '/v1/toolsets' => {
        'object': 'list',
        'platform': 'api_server',
        'data': <Object>[],
      },
      _ => null,
    };
    final code = status[path] ?? (path == '/v1/skills' ? 500 : 200);
    return ResponseBody.fromString(
      jsonEncode(
        code >= 400 || body == null
            ? {
                'error': {
                  'message': 'Failed',
                  'type': 'server_error',
                  'param': null,
                  'code': null,
                },
              }
            : body,
      ),
      code >= 400 || body != null ? code : 404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
