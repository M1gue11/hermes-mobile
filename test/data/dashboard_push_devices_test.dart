import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/dashboard_session_store.dart';
import 'package:hermes_mobile/data/gateway/dashboard_gateway_repository.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';

void main() {
  late _PushAdapter adapter;
  late DashboardGatewayRepository repository;

  setUp(() {
    adapter = _PushAdapter();
    repository = DashboardGatewayRepository(
      store: _Sessions(),
      dio: Dio()..httpClientAdapter = adapter,
    );
  });

  test('lista aparelhos sem chaves e com a data em segundos', () async {
    adapter.reply = (_) => _json({
      'version': 1,
      'encryption': true,
      'devices': [
        {
          'id': 'phone-0001',
          'label': 'Hermes Mobile',
          'endpoint_host': 'ntfy.example.org',
          'encrypted': true,
          'updated_at': 1762560000.5,
        },
        {'label': 'sem id'},
      ],
    });

    final state = await repository.pushDevices();

    expect(
      adapter.requests.single.uri.path,
      '/api/plugins/mobile-push/devices',
    );
    expect(state.encryption, isTrue);
    expect(state.devices.single.id, 'phone-0001');
    expect(state.devices.single.endpointHost, 'ntfy.example.org');
    expect(state.devices.single.updatedAt, isNotNull);
  });

  test('sem o plugin: 404 ou HTML do SPA viram PushPluginMissing', () async {
    adapter.reply = (_) => _json({'detail': 'Not Found'}, 404);
    await expectLater(
      repository.pushDevices(),
      throwsA(isA<PushPluginMissing>()),
    );

    adapter.reply = (_) => ResponseBody.fromString(
      '<!doctype html>',
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );
    await expectLater(
      repository.pushDevices(),
      throwsA(isA<PushPluginMissing>()),
    );

    adapter.reply = (_) => _json({'detail': 'Not Found'}, 404);
    await expectLater(
      repository.removePushDevice('phone-0001'),
      throwsA(isA<PushPluginMissing>()),
    );
  });

  test('registro manda endpoint e chaves; recusa traz a causa', () async {
    adapter.reply = (_) => _json({'id': 'phone-0001'});

    await repository.registerPushDevice((
      deviceId: 'phone 1/x',
      endpoint: 'https://ntfy.example.org/upAbc?up=1',
      label: 'Hermes Mobile',
      p256dh: 'pub',
      auth: null,
    ));

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.uri.path, '/api/plugins/mobile-push/devices/phone%201%2Fx');
    expect(request.data, {
      'endpoint': 'https://ntfy.example.org/upAbc?up=1',
      'label': 'Hermes Mobile',
      'p256dh': 'pub',
      'auth': '',
    });

    adapter.reply = (_) => _json({
      'detail':
          'O endpoint de push precisa ser https (http só em rede privada).',
    }, 400);
    await expectLater(
      repository.registerPushDevice((
        deviceId: 'phone-0001',
        endpoint: 'http://ntfy.sh/upX',
        label: '',
        p256dh: null,
        auth: null,
      )),
      throwsA(
        isA<GatewayOperationException>()
            .having((e) => e, 'type', isNot(isA<PushPluginMissing>()))
            .having((e) => e.message, 'message', contains('https')),
      ),
    );
  });

  test(
    'teste devolve status e aparelho não registrado mantém a causa',
    () async {
      adapter.reply = (_) =>
          _json({'ok': false, 'status': 410, 'encrypted': true, 'gone': true});

      final result = await repository.testPushDevice('phone-0001');

      expect(adapter.requests.single.method, 'POST');
      expect(
        adapter.requests.single.uri.path,
        '/api/plugins/mobile-push/devices/phone-0001/test',
      );
      expect(result, (ok: false, status: 410, encrypted: true, gone: true));

      adapter.reply = (_) => _json({'detail': 'Aparelho não registrado.'}, 404);
      await expectLater(
        repository.testPushDevice('phone-0001'),
        throwsA(
          isA<GatewayOperationException>()
              .having((e) => e, 'type', isNot(isA<PushPluginMissing>()))
              .having((e) => e.message, 'message', 'Aparelho não registrado.'),
        ),
      );
    },
  );
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

final class _PushAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  ResponseBody Function(RequestOptions options) reply = (_) => _json({});

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return reply(options);
  }
}

final class _Sessions implements DashboardSessionStore {
  DashboardSession? session = (
    baseUrl: 'https://dashboard.example:8443',
    cookies: {'session': 'opaque'},
  );

  @override
  Future<DashboardSession?> read() async => session;

  @override
  Future<void> save(DashboardSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<DashboardCredentials?> readCredentials() async => null;

  @override
  Future<void> saveCredentials(DashboardCredentials credentials) async {}

  @override
  Future<void> clearCredentials() async {}
}
