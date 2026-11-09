import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/dashboard_session_store.dart';
import 'package:hermes_mobile/data/gateway/dashboard_gateway_repository.dart';
import 'package:hermes_mobile/domain/models/agent_file.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';

void main() {
  late HttpServer server;
  late Directory temporary;
  late DashboardGatewayRepository repository;
  late _Store store;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    temporary = await Directory.systemTemp.createTemp('hermes-file-test-');
    store = _Store((
      baseUrl: 'http://127.0.0.1:${server.port}',
      cookies: {'session': 'synthetic-test-session'},
    ));
    repository = DashboardGatewayRepository(store: store);
  });

  tearDown(() async {
    await server.close(force: true);
    await temporary.delete(recursive: true);
  });

  test(
    'streams bytes with progress and cookie, without query credentials',
    () async {
      server.listen((request) async {
        expect(request.uri.path, '/api/files/download');
        expect(request.uri.queryParameters, {
          'path': '/srv/relatório & final.pdf',
        });
        expect(
          request.headers.value('cookie'),
          'session=synthetic-test-session',
        );
        request.response.headers.contentType = ContentType(
          'application',
          'pdf',
        );
        request.response.contentLength = 4;
        request.response.add([1, 2]);
        await request.response.flush();
        request.response.add([3, 4]);
        await request.response.close();
      });
      final progress = <int>[];
      final target = '${temporary.path}/file';
      final info = await repository.downloadAgentFile(
        path: '/srv/relatório & final.pdf',
        destination: target,
        onProgress: (received, total) {
          progress.add(received);
          expect(total, 4);
        },
        cancelled: Completer<void>().future,
      );
      expect(await File(target).readAsBytes(), [1, 2, 3, 4]);
      expect(info, (size: 4, mimeType: 'application/pdf'));
      expect(progress.first, 0);
      expect(progress.last, 4);
    },
  );

  for (final status in [403, 404, 409, 413]) {
    test(
      'server refusal $status never saves its error body as a file',
      () async {
        server.listen((request) async {
          request.response.statusCode = status;
          request.response.write('private server error');
          await request.response.close();
        });
        final target = '${temporary.path}/file';
        await expectLater(
          repository.downloadAgentFile(
            path: '/srv/file.pdf',
            destination: target,
            onProgress: (_, _) {},
            cancelled: Completer<void>().future,
          ),
          throwsA(
            isA<GatewayOperationException>()
                .having((e) => e.httpStatus, 'status', status)
                .having(
                  (e) => e.message.contains('private server error'),
                  'safe error',
                  false,
                ),
          ),
        );
        expect(await File(target).exists(), isFalse);
      },
    );
  }

  test('redirect never receives the authenticated request', () async {
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.statusCode = 302;
      request.response.headers.set('location', '/another-host');
      await request.response.close();
    });
    await expectLater(
      repository.downloadAgentFile(
        path: '/srv/file.pdf',
        destination: '${temporary.path}/file',
        onProgress: (_, _) {},
        cancelled: Completer<void>().future,
      ),
      throwsA(isA<GatewayOperationException>()),
    );
    expect(requests, 1);
  });

  test('expired login asks to authenticate and creates no file', () async {
    server.listen((request) async {
      request.response.statusCode = 401;
      await request.response.close();
    });
    final target = '${temporary.path}/file';
    await expectLater(
      repository.downloadAgentFile(
        path: '/srv/file.pdf',
        destination: target,
        onProgress: (_, _) {},
        cancelled: Completer<void>().future,
      ),
      throwsA(isA<GatewayAuthenticationRequired>()),
    );
    expect(store.session, isNull);
    expect(await File(target).exists(), isFalse);
  });

  test(
    'cancelling closes a download still waiting for response headers',
    () async {
      final requested = Completer<void>();
      server.listen((request) {
        requested.complete();
      });
      final cancel = Completer<void>();
      final result = repository.downloadAgentFile(
        path: '/srv/file.pdf',
        destination: '${temporary.path}/file',
        onProgress: (_, _) {},
        cancelled: cancel.future,
      );
      final assertion = expectLater(
        result,
        throwsA(isA<AgentFileDownloadCancelled>()),
      );
      await requested.future;
      cancel.complete();
      await assertion;
    },
  );
}

class _Store implements DashboardSessionStore {
  _Store(this.session);
  DashboardSession? session;
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
