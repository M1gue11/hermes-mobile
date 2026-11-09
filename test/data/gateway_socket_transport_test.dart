import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/gateway/dashboard_gateway_repository.dart';

void main() {
  test('A92: upgrade WS não segue redirect com Cookie nem ticket', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var requests = 0;
    server.listen((request) async {
      requests++;
      request.response.statusCode = HttpStatus.found;
      request.response.headers.set(
        'location',
        'http://127.0.0.1:${server.port}/outside',
      );
      await request.response.close();
    });
    await expectLater(
      IoGatewaySocket.connect(
        Uri.parse('ws://127.0.0.1:${server.port}/api/ws?ticket=synthetic'),
        headers: {'Cookie': 'session=synthetic'},
      ),
      throwsA(isA<WebSocketException>()),
    );
    expect(requests, 1);
  });

  test(
    'A92: upgrade WS continua funcionando e pode fechar normalmente',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.add('ready');
        socket.listen((_) {}, onDone: () => socket.close());
      });
      final socket = await IoGatewaySocket.connect(
        Uri.parse('ws://127.0.0.1:${server.port}/api/ws'),
        headers: {},
      );
      expect(await socket.stream.first, 'ready');
      await socket.close();
    },
  );
}
