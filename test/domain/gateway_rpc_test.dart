import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/gateway_rpc.dart';

void main() {
  test('correlaciona resultado por id', () {
    final frame = decodeGatewayFrame(
      '{"jsonrpc":"2.0","id":"m1","result":{"session_id":"live"}}',
    );

    expect(frame, isA<GatewayResultFrame>());
    expect((frame as GatewayResultFrame).id, 'm1');
    expect((frame.result as Map<String, dynamic>)['session_id'], 'live');
  });

  test('erro é uma resposta terminal do mesmo id', () {
    final frame =
        decodeGatewayFrame(
              '{"jsonrpc":"2.0","id":"m2","error":{"code":4006,"message":"session_id required"}}',
            )
            as GatewayErrorFrame;

    expect(frame.id, 'm2');
    expect(frame.code, 4006);
  });

  test('evento desconhecido não derruba o codec', () {
    final frame =
        decodeGatewayFrame(
              '{"jsonrpc":"2.0","method":"event","params":{"type":"future.event","payload":{"ok":true}}}',
            )
            as GatewayEventFrame;

    expect(frame.type, 'future.event');
    expect(frame.payload['ok'], isTrue);
  });

  test('decodifica pedido server→client preservando id e params', () {
    final frame = decodeGatewayFrame(
      '{"jsonrpc":"2.0","id":"srq-1","method":"clarify",'
      '"params":{"session_id":"live","questions":[]}}',
    );

    expect(frame, isA<GatewayServerRequestFrame>());
    final request = frame as GatewayServerRequestFrame;
    expect(request.id, 'srq-1');
    expect(request.method, 'clarify');
    expect(request.params['session_id'], 'live');
  });

  test('pedido server→client exige id textual e params objeto', () {
    expect(
      () => decodeGatewayFrame(
        '{"jsonrpc":"2.0","id":7,"method":"clarify","params":{}}',
      ),
      throwsA(isA<GatewayProtocolException>()),
    );
    expect(
      () => decodeGatewayFrame(
        '{"jsonrpc":"2.0","id":"srq-2","method":"clarify","params":[]}',
      ),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('frame malformado falha sem aceitar prefixo válido', () {
    expect(
      () => decodeGatewayFrame('{"jsonrpc":"2.0"}\n{}'),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('resposta ambígua com result e error é recusada', () {
    expect(
      () => decodeGatewayFrame(
        '{"jsonrpc":"2.0","id":"m3","result":{},"error":{"code":-1,"message":"falhou"}}',
      ),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('resposta terminal exige id textual não vazio', () {
    expect(
      () => decodeGatewayFrame('{"jsonrpc":"2.0","result":{}}'),
      throwsA(isA<GatewayProtocolException>()),
    );
    expect(
      () => decodeGatewayFrame('{"jsonrpc":"2.0","id":7,"result":{}}'),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('erro terminal exige code inteiro e message não vazia', () {
    expect(
      () => decodeGatewayFrame(
        '{"jsonrpc":"2.0","id":"m4","error":{"message":"falhou"}}',
      ),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('notificação do servidor não aceita id', () {
    expect(
      () => decodeGatewayFrame(
        '{"jsonrpc":"2.0","id":"m5","method":"event","params":{"type":"gateway.ready","payload":{}}}',
      ),
      throwsA(isA<GatewayProtocolException>()),
    );
  });

  test('codifica exatamente um request JSON-RPC', () {
    expect(
      encodeGatewayRequest(
        id: 'm3',
        method: 'file.attach',
        params: const {'session_id': 'live'},
      ),
      '{"jsonrpc":"2.0","id":"m3","method":"file.attach","params":{"session_id":"live"}}',
    );
  });

  test('não codifica request sem correlação ou método', () {
    expect(
      () => encodeGatewayRequest(id: '', method: 'session.list'),
      throwsArgumentError,
    );
    expect(
      () => encodeGatewayRequest(id: 'm6', method: ''),
      throwsArgumentError,
    );
  });
}
