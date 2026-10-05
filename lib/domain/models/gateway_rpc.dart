import 'dart:convert';

/// Um frame JSON-RPC recebido do gateway TUI.
sealed class GatewayFrame {
  const GatewayFrame();
}

final class GatewayResultFrame extends GatewayFrame {
  const GatewayResultFrame({required this.id, required this.result});

  final String id;
  final Object? result;
}

final class GatewayErrorFrame extends GatewayFrame {
  const GatewayErrorFrame({
    required this.id,
    required this.code,
    required this.message,
    this.data,
  });

  final String id;
  final int code;
  final String message;
  final Object? data;
}

/// Pedido JSON-RPC do servidor para o cliente (server→client request).
///
/// O [id] deste envelope é a correlação da resposta: ele não é substituído
/// pelo `request_id` opcional dos parâmetros de uma aprovação.
final class GatewayServerRequestFrame extends GatewayFrame {
  const GatewayServerRequestFrame({
    required this.id,
    required this.method,
    required this.params,
  });

  final String id;
  final String method;
  final Map<String, dynamic> params;
}

final class GatewayEventFrame extends GatewayFrame {
  const GatewayEventFrame({required this.type, required this.payload});

  final String type;
  final Map<String, dynamic> payload;
}

final class GatewayProtocolException implements Exception {
  const GatewayProtocolException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Decodifica exatamente um objeto JSON-RPC por frame de texto.
///
/// Eventos desconhecidos continuam sendo [GatewayEventFrame]. A decisão de
/// ignorá-los pertence ao consumidor e não derruba o socket.
GatewayFrame decodeGatewayFrame(String raw) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw const GatewayProtocolException('Frame JSON-RPC malformado.');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const GatewayProtocolException('Frame JSON-RPC não é um objeto.');
  }
  if (decoded['jsonrpc'] != '2.0') {
    throw const GatewayProtocolException('Versão JSON-RPC não suportada.');
  }

  final hasId = decoded.containsKey('id');
  final hasResult = decoded.containsKey('result');
  final hasError = decoded.containsKey('error');
  if (hasResult || hasError) {
    if (!hasId ||
        decoded['id'] is! String ||
        (decoded['id'] as String).isEmpty) {
      throw const GatewayProtocolException('Resposta JSON-RPC sem id válido.');
    }
    if (hasResult == hasError) {
      throw const GatewayProtocolException(
        'Resposta JSON-RPC deve conter result ou error.',
      );
    }
    final id = decoded['id'] as String;
    if (hasResult) return GatewayResultFrame(id: id, result: decoded['result']);

    final rawError = decoded['error'];
    if (rawError is! Map<String, dynamic> ||
        rawError['code'] is! int ||
        rawError['message'] is! String ||
        (rawError['message'] as String).isEmpty) {
      throw const GatewayProtocolException('Erro JSON-RPC sem shape válido.');
    }
    return GatewayErrorFrame(
      id: id,
      code: rawError['code'] as int,
      message: rawError['message'] as String,
      data: rawError['data'],
    );
  }
  if (decoded['method'] == 'event' &&
      decoded['params'] is Map<String, dynamic>) {
    if (hasId) {
      throw const GatewayProtocolException(
        'Notificação JSON-RPC não pode conter id.',
      );
    }
    final params = decoded['params'] as Map<String, dynamic>;
    final type = params['type']?.toString();
    if (type == null || type.isEmpty) {
      throw const GatewayProtocolException('Evento do gateway sem tipo.');
    }
    final payload = params['payload'];
    return GatewayEventFrame(
      type: type,
      payload: payload is Map<String, dynamic> ? payload : const {},
    );
  }
  if (hasId && decoded['method'] is String) {
    final id = decoded['id'];
    final method = decoded['method'] as String;
    if (id is! String || id.isEmpty || method.isEmpty) {
      throw const GatewayProtocolException(
        'Pedido JSON-RPC do servidor sem correlação válida.',
      );
    }
    final rawParams = decoded['params'];
    if (rawParams != null && rawParams is! Map<String, dynamic>) {
      throw const GatewayProtocolException(
        'Pedido JSON-RPC do servidor tem params inválidos.',
      );
    }
    return GatewayServerRequestFrame(
      id: id,
      method: method,
      params: rawParams is Map<String, dynamic> ? rawParams : const {},
    );
  }
  throw const GatewayProtocolException('Envelope JSON-RPC não reconhecido.');
}

String encodeGatewayRequest({
  required String id,
  required String method,
  Map<String, dynamic> params = const {},
}) {
  if (id.isEmpty) throw ArgumentError.value(id, 'id', 'não pode ser vazio');
  if (method.isEmpty) {
    throw ArgumentError.value(method, 'method', 'não pode ser vazio');
  }
  return jsonEncode({
    'jsonrpc': '2.0',
    'id': id,
    'method': method,
    if (params.isNotEmpty) 'params': params,
  });
}
