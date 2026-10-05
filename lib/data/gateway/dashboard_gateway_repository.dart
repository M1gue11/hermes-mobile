import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/diagnostics/turn_capture.dart';
import '../../domain/models/approval_request.dart';
import '../../domain/models/clarify_request.dart';
import '../../domain/models/composer_attachment.dart';
import '../../domain/models/gateway_rpc.dart';
import '../../domain/models/run.dart';
import '../../domain/models/run_event.dart';
import '../../domain/models/session_message.dart';
import '../../domain/models/tool_call.dart';
import '../../domain/models/tool_preview.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../config/dashboard_session_store.dart';

typedef GatewaySocketConnector =
    Future<GatewaySocket> Function(
      Uri uri, {
      required Map<String, dynamic> headers,
    });

/// Casca mínima sobre `dart:io WebSocket`, injetável nos testes sem rede.
abstract interface class GatewaySocket {
  Stream<dynamic> get stream;
  int? get closeCode;
  void add(String data);
  Future<void> close();
}

final class IoGatewaySocket implements GatewaySocket {
  IoGatewaySocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get stream => _socket;

  @override
  int? get closeCode => _socket.closeCode;

  @override
  void add(String data) => _socket.add(data);

  @override
  Future<void> close() async => _socket.close();
}

class DashboardGatewayRepository implements GatewayRepository {
  static const invalidBaseUrlMessage =
      'Use HTTPS ou HTTP em um host MagicDNS do Tailnet (*.ts.net).';

  /// O gateway só anuncia esse keepalive em `gateway.ready.heartbeat`.
  /// Os valores acompanham o cliente Desktop: uma sondagem a cada 15 s e
  /// teardown após 45 s sem qualquer frame de entrada.
  static const gatewayHeartbeatInterval = Duration(seconds: 15);
  static const gatewayHeartbeatDeadline = Duration(seconds: 45);

  DashboardGatewayRepository({
    required this.store,
    Dio? dio,
    GatewaySocketConnector? socketConnector,
    Duration heartbeatInterval = gatewayHeartbeatInterval,
    Duration heartbeatDeadline = gatewayHeartbeatDeadline,
  }) : _dio = dio ?? Dio(),
       _socketConnector = socketConnector ?? _connectIoSocket,
       // ignore: prefer_initializing_formals
       _heartbeatInterval = heartbeatInterval,
       // ignore: prefer_initializing_formals
       _heartbeatDeadline = heartbeatDeadline;

  /// Tempo que uma conexão preparada por [attachFile] espera pelo envio antes
  /// de ser devolvida ao gateway.
  static const stagedSessionTtl = Duration(minutes: 3);

  final DashboardSessionStore store;
  final Dio _dio;
  final GatewaySocketConnector _socketConnector;
  final Duration _heartbeatInterval;
  final Duration _heartbeatDeadline;
  _StagedGatewaySession? _staged;

  static Future<GatewaySocket> _connectIoSocket(
    Uri uri, {
    required Map<String, dynamic> headers,
  }) async => IoGatewaySocket(
    await WebSocket.connect(uri.toString(), headers: headers),
  );

  @override
  Future<bool> hasSession() async =>
      await store.read() != null || await store.readCredentials() != null;

  @override
  Future<void> authenticate({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final session = await _login(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
    await store.saveCredentials((
      baseUrl: session.baseUrl,
      username: username.trim(),
      password: password,
    ));
  }

  Future<DashboardSession> _login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final normalized = _normalizeBaseUrl(baseUrl);
    if (normalized == null) {
      throw const GatewayOperationException(invalidBaseUrlMessage);
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$normalized/auth/password-login',
        data: {
          'provider': 'basic',
          'username': username.trim(),
          'password': password,
        },
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode != 200 || response.data?['ok'] != true) {
        if (response.statusCode == 401) {
          throw const GatewayCredentialsRejected(
            'Usuário ou senha do Dashboard inválidos.',
          );
        }
        throw GatewayOperationException(
          'O Dashboard recusou o login (${response.statusCode}).',
        );
      }
      final cookies = _cookiesFrom(response.headers);
      if (cookies.isEmpty) {
        throw const GatewayOperationException(
          'O Dashboard não devolveu uma sessão segura.',
        );
      }
      final session = (baseUrl: normalized, cookies: cookies);
      await store.save(session);
      return session;
    } on DioException catch (error) {
      throw GatewayOperationException(
        error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout
            ? 'O Dashboard não respondeu a tempo.'
            : 'Não foi possível alcançar o Dashboard pelo Tailnet.',
      );
    }
  }

  @override
  Future<ComposerAttachment> attachFile({
    required String storedSessionId,
    required ComposerAttachment attachment,
  }) async {
    final stored = storedSessionId.trim();
    if (stored.isEmpty) {
      throw const GatewayOperationException(
        'A conversa não tem um identificador durável.',
      );
    }
    final attached = await _attachWithRetry(stored, attachment);
    final refText = attached['ref_text']?.toString();
    if (refText == null || refText.isEmpty) {
      // A conexão respondeu, então ela continua servindo ao envio; o que falhou
      // foi o contrato. Repetir aqui só duplicaria o arquivo no workspace.
      throw const GatewayOperationException(
        'O gateway recebeu o arquivo, mas não devolveu sua referência.',
        method: 'file.attach',
      );
    }
    return attachment.copyWith(
      status: ComposerAttachmentStatus.uploaded,
      refText: refText,
      error: null,
    );
  }

  Future<Map<String, dynamic>> _attachWithRetry(
    String storedSessionId,
    ComposerAttachment attachment,
  ) async {
    try {
      return await _attachOnce(storedSessionId, attachment);
    } on GatewayAuthenticationRequired {
      await _discardStagedSession();
      rethrow;
    } catch (error) {
      await _discardStagedSession();
      if (!_isRetryableGatewayFailure(error)) throw _attachFailure(error);
      // Falha transitória do gateway — sessão reciclada entre o anexo e agora,
      // handler quebrado ou canal morto. A segunda tentativa vai por conexão
      // nova; no pior caso sobra uma cópia órfã do arquivo no workspace, nunca
      // um anexo que a pessoa acha que enviou.
      try {
        return await _attachOnce(storedSessionId, attachment);
      } on GatewayAuthenticationRequired {
        await _discardStagedSession();
        rethrow;
      } catch (retried) {
        await _discardStagedSession();
        throw _attachFailure(retried);
      }
    }
  }

  Future<Map<String, dynamic>> _attachOnce(
    String storedSessionId,
    ComposerAttachment attachment,
  ) async {
    final staged = await _stageSession(storedSessionId);
    return staged.client.call('file.attach', {
      'session_id': staged.liveSessionId,
      'path': attachment.localPath ?? attachment.name,
      'name': attachment.name,
      'data_url': _dataUrl(attachment),
    });
  }

  /// Retoma a conversa uma única vez e mantém o socket aberto para o envio.
  ///
  /// O gateway usa o socket que retomou a sessão como transporte dela. Fechar
  /// esse socket logo após o `file.attach` deixa a sessão órfã, e o reaper do
  /// gateway pode derrubá-la — junto do `SessionDB` do build que o próprio
  /// attach acabou de disparar — antes do `prompt.submit`. Por isso a mesma
  /// conexão atravessa anexo e envio, como faz o Desktop, e a retomada usa
  /// `eager_build` para não largar um build em curso sem transporte.
  Future<_StagedGatewaySession> _stageSession(String storedSessionId) async {
    final current = _staged;
    if (current != null && current.storedSessionId == storedSessionId) {
      _armStagedExpiry(current);
      return current;
    }
    await _discardStagedSession();

    final client = await _openSocketClient();
    try {
      final resumed = await client.call('session.resume', {
        'session_id': storedSessionId,
        'source': 'mobile',
        'close_on_disconnect': false,
        'eager_build': true,
        'omit_messages': true,
      });
      final liveSessionId = resumed['session_id']?.toString().trim() ?? '';
      if (liveSessionId.isEmpty) {
        throw const GatewayOperationException(
          'O gateway não devolveu a sessão ativa.',
          method: 'session.resume',
        );
      }
      client.bindSessionId(liveSessionId);
      final staged = _StagedGatewaySession(
        client: client,
        storedSessionId: storedSessionId,
        liveSessionId: liveSessionId,
        running: _sessionIsRunning(resumed),
      );
      _staged = staged;
      _armStagedExpiry(staged);
      return staged;
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  /// Anexar e desistir do envio não pode segurar um socket para sempre. A
  /// contagem recomeça a cada uso, então uma sequência de anexos não expira no
  /// meio.
  void _armStagedExpiry(_StagedGatewaySession staged) {
    staged.expiry?.cancel();
    staged.expiry = Timer(
      stagedSessionTtl,
      () => unawaited(_discardStagedSession(staged)),
    );
  }

  /// Entrega a conexão preparada ao turno, ou `null` quando não serve a ela.
  _StagedGatewaySession? _claimStagedSession(String storedSessionId) {
    final staged = _staged;
    if (staged == null) return null;
    _staged = null;
    staged.expiry?.cancel();
    if (staged.storedSessionId != storedSessionId) {
      unawaited(staged.client.close());
      return null;
    }
    return staged;
  }

  Future<void> _discardStagedSession([_StagedGatewaySession? only]) async {
    final staged = _staged;
    if (staged == null) return;
    if (only != null && !identical(staged, only)) return;
    _staged = null;
    staged.expiry?.cancel();
    await staged.client.close();
  }

  static bool _isRetryableGatewayFailure(Object error) => switch (error) {
    GatewayCredentialsRejected() => false,
    // Sem código: o canal caiu antes de o gateway responder — típico de uma
    // conexão preparada que morreu enquanto a pessoa terminava de escrever.
    GatewayOperationException(:final code) =>
      code == null || const {-32000, 4001, 5032}.contains(code),
    WebSocketException() => true,
    _ => false,
  };

  static GatewayOperationException _attachFailure(Object error) =>
      switch (error) {
        GatewayOperationException() => error,
        TimeoutException() => const GatewayOperationException(
          'O gateway demorou demais para preparar o anexo.',
          method: 'file.attach',
        ),
        WebSocketException() => const GatewayOperationException(
          'Não foi possível abrir o canal seguro de anexos.',
          method: 'file.attach',
        ),
        _ => const GatewayOperationException(
          'Não foi possível preparar o anexo.',
          method: 'file.attach',
        ),
      };

  @override
  Future<String> transcribeAudio(ComposerAttachment attachment) async {
    if (attachment.kind != ComposerAttachmentKind.audio) {
      throw const GatewayOperationException('O anexo não é uma gravação.');
    }
    final session = await _requireSession();
    final response = await _authorizedPost(
      session,
      '/api/audio/transcribe',
      data: {
        'data_url': _dataUrl(attachment),
        'mime_type': attachment.mimeType,
      },
      receiveTimeout: const Duration(minutes: 8),
    );
    final transcript = response.data?['transcript']?.toString().trim() ?? '';
    if (transcript.isEmpty) {
      throw const GatewayOperationException(
        'Nenhuma fala foi detectada na gravação.',
      );
    }
    return transcript;
  }

  @override
  Future<List<SessionMessage>> conversationHistory({
    required String storedSessionId,
  }) async {
    final stored = storedSessionId.trim();
    if (stored.isEmpty) {
      throw const GatewayOperationException(
        'A conversa não tem um identificador durável.',
        method: 'session.history',
      );
    }

    // `session.history` aceita o id durável diretamente. Não usamos
    // `session.resume` aqui: reidratar uma tela concluída não deve criar uma
    // sessão live nem disputar o socket de um turno que ainda esteja rodando.
    final client = await _openSocketClient();
    try {
      final result = await client.call('session.history', {
        'session_id': stored,
      });
      return _historyFrom(result);
    } finally {
      await client.close();
    }
  }

  @override
  Future<GatewayLiveTurn> openLiveTurn({
    required String storedSessionId,
  }) async {
    final stored = storedSessionId.trim();
    if (stored.isEmpty) {
      throw const GatewayOperationException(
        'A conversa não tem um identificador durável.',
      );
    }

    // A conexão que preparou os anexos já retomou esta sessão e segue sendo o
    // transporte dela: usá-la aqui é o que mantém anexo e envio no mesmo
    // socket, sem uma segunda retomada nem uma janela sem transporte.
    final staged = _claimStagedSession(stored);
    if (staged != null) {
      try {
        return await _liveTurnFrom(
          client: staged.client,
          storedSessionId: stored,
          liveSessionId: staged.liveSessionId,
          running: staged.running,
        );
      } catch (_) {
        // Nenhum prompt foi submetido nessa conexão, então abrir outra não
        // duplica turno.
        await staged.client.close();
      }
    }

    final client = await _openSocketClient();
    try {
      final resumed = await client.call('session.resume', {
        'session_id': stored,
        'source': 'mobile',
        'close_on_disconnect': false,
        'eager_build': true,
      });
      final liveSessionId = resumed['session_id']?.toString().trim() ?? '';
      if (liveSessionId.isEmpty) {
        throw const GatewayOperationException(
          'O gateway não devolveu a sessão live.',
          method: 'session.resume',
        );
      }
      client.bindSessionId(liveSessionId);
      return await _liveTurnFrom(
        client: client,
        storedSessionId: stored,
        liveSessionId: liveSessionId,
        running: _sessionIsRunning(resumed),
        resumedHistory: _historyFrom(resumed),
      );
    } catch (_) {
      await client.close();
      rethrow;
    }
  }

  @override
  Future<List<GatewayProbeStep>> probeGateway({String? storedSessionId}) async {
    final stored = storedSessionId?.trim() ?? '';
    final steps = <GatewayProbeStep>[];

    final _GatewaySocketClient client;
    try {
      client = await _openSocketClient();
    } catch (error) {
      return [
        GatewayProbeStep(
          method: 'gateway.ready',
          ok: false,
          detail: _probeFailure(error),
        ),
      ];
    }
    steps.add(
      const GatewayProbeStep(
        method: 'gateway.ready',
        ok: true,
        detail: 'socket aberto e handshake concluído',
      ),
    );

    Future<void> run(String method, Map<String, dynamic> params) async {
      try {
        final result = await client.call(method, params);
        steps.add(
          GatewayProbeStep(
            method: method,
            ok: true,
            detail: result.isEmpty
                ? 'resposta vazia'
                : 'campos {${result.keys.take(8).join(",")}}',
          ),
        );
      } catch (error) {
        steps.add(
          GatewayProbeStep(
            method: method,
            ok: false,
            detail: _probeFailure(error),
          ),
        );
      }
    }

    try {
      // Leitura primeiro: se estas passarem, o `SessionDB` do gateway responde.
      await run('session.list', {'limit': 1});
      await run('session.most_recent', const {});
      if (stored.isNotEmpty) {
        await run('session.history', {'session_id': stored});
        // Por último, e igual ao envio real, porque é o que estamos caçando.
        await run('session.resume', {
          'session_id': stored,
          'source': 'mobile',
          'close_on_disconnect': false,
          'eager_build': true,
        });
      }
    } finally {
      await client.close();
    }
    return steps;
  }

  /// Mantém método, código e texto do gateway, que aqui são o diagnóstico.
  /// Este texto vai para a tela de debug, nunca para a conversa.
  static String _probeFailure(Object error) => switch (error) {
    GatewayOperationException(:final code, :final detail) =>
      '${code == null ? "" : "code=$code "}${detail ?? ""}'.trim(),
    _ => error.runtimeType.toString(),
  };

  Future<GatewayLiveTurn> _liveTurnFrom({
    required _GatewaySocketClient client,
    required String storedSessionId,
    required String liveSessionId,
    required bool running,
    List<SessionMessage> resumedHistory = const [],
  }) async {
    // O contrato medido do 0.20.1 já devolve `messages` no `session.resume`.
    // Esse snapshot pertence à mesma operação que estabeleceu a sessão live e
    // evita trocá-lo logo depois por um `session.history` eventualmente parcial.
    var initialHistory = resumedHistory;
    if (initialHistory.isEmpty) {
      final historyResult = await client.call('session.history', {
        'session_id': liveSessionId,
      });
      initialHistory = _historyFrom(historyResult);
    }
    return _DashboardLiveTurn(
      client: client,
      storedSessionId: storedSessionId,
      liveSessionId: liveSessionId,
      running: running,
      initialHistory: initialHistory,
    );
  }

  Future<_GatewaySocketClient> _openSocketClient({
    bool retryTicket = true,
  }) async {
    final session = await _requireSession();
    final ticket = await _mintTicket(session);
    final wsUri = _webSocketUri(session.baseUrl, ticket);

    GatewaySocket? socket;
    _GatewaySocketClient? client;
    try {
      socket = await _socketConnector(
        wsUri,
        headers: {'Origin': session.baseUrl},
      ).timeout(const Duration(seconds: 15));
      client = _GatewaySocketClient(
        socket,
        heartbeatInterval: _heartbeatInterval,
        heartbeatDeadline: _heartbeatDeadline,
      );
      await client.ready.timeout(const Duration(seconds: 20));
      return client;
    } on GatewayAuthenticationRequired {
      await client?.close();
      if (client == null) await socket?.close();
      if (retryTicket) return _openSocketClient(retryTicket: false);
      rethrow;
    } on TimeoutException {
      await client?.close();
      if (client == null) await socket?.close();
      throw const GatewayOperationException(
        'O gateway demorou demais para iniciar o live chat.',
      );
    } on WebSocketException {
      await client?.close();
      if (client == null) await socket?.close();
      throw const GatewayOperationException(
        'Não foi possível abrir o canal seguro do live chat.',
      );
    } on GatewayOperationException {
      await client?.close();
      if (client == null) await socket?.close();
      rethrow;
    }
  }

  Future<String> _mintTicket(DashboardSession session) async {
    final response = await _authorizedPost(
      session,
      '/api/auth/ws-ticket',
      data: const {},
    );
    final ticket = response.data?['ticket']?.toString();
    if (ticket == null || ticket.isEmpty) {
      throw const GatewayOperationException(
        'O Dashboard não devolveu um ticket WebSocket.',
      );
    }
    return ticket;
  }

  Future<Response<Map<String, dynamic>>> _authorizedPost(
    DashboardSession session,
    String path, {
    required Map<String, dynamic> data,
    Duration? receiveTimeout,
    bool renewSession = true,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${session.baseUrl}$path',
        data: data,
        options: Options(
          headers: {'Cookie': _cookieHeader(session.cookies)},
          receiveTimeout: receiveTimeout,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      if (response.statusCode == 401) {
        await store.clear();
        if (renewSession) {
          final renewed = await _renewSession();
          if (renewed != null) {
            return _authorizedPost(
              renewed,
              path,
              data: data,
              receiveTimeout: receiveTimeout,
              renewSession: false,
            );
          }
        }
        throw const GatewayAuthenticationRequired(
          'O login salvo não está mais válido. Entre novamente.',
        );
      }
      if (response.statusCode == null || response.statusCode! >= 400) {
        final detail = response.data?['detail']?.toString();
        throw GatewayOperationException(
          detail?.isNotEmpty == true
              ? detail!
              : 'O Dashboard recusou a operação (${response.statusCode}).',
        );
      }
      final merged = {...session.cookies, ..._cookiesFrom(response.headers)};
      if (merged.length != session.cookies.length ||
          !_sameCookies(merged, session.cookies)) {
        await store.save((baseUrl: session.baseUrl, cookies: merged));
      }
      return response;
    } on DioException catch (error) {
      throw GatewayOperationException(
        error.type == DioExceptionType.receiveTimeout
            ? 'O Dashboard não concluiu a operação a tempo.'
            : 'Não foi possível alcançar o Dashboard pelo Tailnet.',
      );
    }
  }

  Future<DashboardSession> _requireSession() async {
    final session = await store.read() ?? await _renewSession();
    if (session == null) throw const GatewayAuthenticationRequired();
    return session;
  }

  Future<DashboardSession?> _renewSession() async {
    final credentials = await store.readCredentials();
    if (credentials == null) return null;
    try {
      return await _login(
        baseUrl: credentials.baseUrl,
        username: credentials.username,
        password: credentials.password,
      );
    } on GatewayCredentialsRejected {
      await store.clearCredentials();
      return null;
    }
  }

  static String? _normalizeBaseUrl(String raw) {
    final uri = Uri.tryParse(raw.trim().replaceFirst(RegExp(r'/+$'), ''));
    if (uri == null ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.path.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      return null;
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') return null;
    if (scheme == 'http' && !_isTailnetHost(uri.host)) return null;
    return uri.replace(scheme: scheme).toString();
  }

  static bool supportsBaseUrl(String raw) => _normalizeBaseUrl(raw) != null;

  static bool _isTailnetHost(String host) {
    final normalized = host.toLowerCase();
    return normalized.endsWith('.ts.net');
  }

  static Uri _webSocketUri(String baseUrl, String ticket) {
    final baseUri = Uri.parse(baseUrl);
    return baseUri.replace(
      scheme: baseUri.scheme == 'http' ? 'ws' : 'wss',
      path: '/api/ws',
      queryParameters: {'ticket': ticket},
    );
  }

  static String _dataUrl(ComposerAttachment attachment) =>
      'data:${attachment.mimeType};base64,${base64Encode(attachment.bytes)}';

  static Map<String, String> _cookiesFrom(Headers headers) {
    final cookies = <String, String>{};
    for (final raw in headers.map['set-cookie'] ?? const <String>[]) {
      final first = raw.split(';').first.trim();
      final separator = first.indexOf('=');
      if (separator <= 0) continue;
      cookies[first.substring(0, separator)] = first.substring(separator + 1);
    }
    return cookies;
  }

  static String _cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');

  static bool _sameCookies(
    Map<String, String> left,
    Map<String, String> right,
  ) =>
      left.length == right.length &&
      left.entries.every((entry) => right[entry.key] == entry.value);

  static bool _sessionIsRunning(Map<String, dynamic> resumed) {
    final running = resumed['running'];
    if (running == true) return true;
    final inflight = resumed['inflight'];
    if (inflight == true || (inflight is List && inflight.isNotEmpty)) {
      return true;
    }
    return switch (resumed['status']?.toString().toLowerCase()) {
      'running' || 'streaming' || 'thinking' || 'busy' => true,
      _ => false,
    };
  }

  static List<SessionMessage> _historyFrom(Map<String, dynamic> result) {
    final rawMessages = result['messages'];
    if (rawMessages is! List) return const [];
    final messages = <SessionMessage>[];
    for (var index = 0; index < rawMessages.length; index++) {
      final raw = rawMessages[index];
      if (raw is! Map) continue;
      final json = raw.map((key, value) => MapEntry(key.toString(), value));
      final role = json['role']?.toString().trim() ?? '';
      if (role.isEmpty) continue;
      messages.add(
        SessionMessage(
          id: json['id']?.toString().trim().isNotEmpty == true
              ? json['id'].toString()
              : 'gateway-history-$index',
          role: role,
          content: _contentText(json['content']),
          timestamp: _timestamp(json['timestamp'] ?? json['created_at']),
          reasoning: _optionalText(json['reasoning']),
          reasoningContent: _optionalText(json['reasoning_content']),
          toolName: _optionalText(json['tool_name']),
          toolCallId: _optionalText(json['tool_call_id']),
          toolCalls: json['tool_calls'],
          tokenCount: json['token_count'] is num
              ? json['token_count'] as num
              : null,
          finishReason: _optionalText(json['finish_reason']),
        ),
      );
    }
    return messages;
  }

  static String _contentText(Object? value) {
    if (value is String) return value;
    if (value is List) {
      return value
          .map((part) {
            if (part is String) return part;
            if (part is Map) {
              return part['text']?.toString() ??
                  part['content']?.toString() ??
                  '';
            }
            return '';
          })
          .where((text) => text.isNotEmpty)
          .join();
    }
    return value?.toString() ?? '';
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static DateTime? _timestamp(Object? value) {
    if (value is num) {
      final millis = value.abs() < 100000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(millis.round(), isUtc: true);
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

/// Conexão já retomada por um `file.attach` e mantida aberta até o envio.
final class _StagedGatewaySession {
  _StagedGatewaySession({
    required this.client,
    required this.storedSessionId,
    required this.liveSessionId,
    required this.running,
  });

  final _GatewaySocketClient client;
  final String storedSessionId;
  final String liveSessionId;
  final bool running;
  Timer? expiry;
}

final class _DashboardLiveTurn implements GatewayLiveTurn {
  _DashboardLiveTurn({
    required this._client,
    required this.storedSessionId,
    required this.liveSessionId,
    required this.running,
    required this.initialHistory,
  });

  final _GatewaySocketClient _client;

  @override
  final String storedSessionId;

  @override
  final String liveSessionId;

  @override
  final bool running;

  @override
  final List<SessionMessage> initialHistory;

  @override
  String get turnId => 'gateway:$liveSessionId';

  @override
  Stream<RunEvent> get events => _client.events.asyncExpand((frame) async* {
    yield* Stream<RunEvent>.fromIterable(_eventsFrom(frame, turnId));
  });

  @override
  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const GatewayOperationException('A mensagem não pode estar vazia.');
    }
    await _client.call('prompt.submit', {
      'session_id': liveSessionId,
      'text': trimmed,
    });
  }

  @override
  Future<void> steer(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const GatewayOperationException(
        'A orientação não pode estar vazia.',
      );
    }
    await _client.call('session.steer', {
      'session_id': liveSessionId,
      'text': trimmed,
    });
  }

  @override
  Future<void> interrupt() async {
    await _client.call('session.interrupt', {'session_id': liveSessionId});
  }

  @override
  Future<void> respondToApproval(
    ApprovalChoice choice, {
    String? requestId,
  }) async {
    if (requestId?.trim().isNotEmpty == true) {
      // O contrato do server request fixa `all: false`; "aprovar para a sessão"
      // é a escolha `session`, não o flag.
      _client.respondToServerRequest(requestId!, {
        'choice': choice.wireValue,
        'all': false,
      });
      return;
    }
    await _client.call('approval.respond', {
      'session_id': liveSessionId,
      'choice': choice.wireValue,
      'all': false,
    });
  }

  @override
  Future<ClarifyResponse> lockClarification({
    required String requestId,
    required String questionId,
    required Object answer,
  }) async {
    final normalized = _clarifyAnswerWire(answer);
    if (requestId.trim().isEmpty ||
        questionId.trim().isEmpty ||
        normalized == null) {
      throw const GatewayOperationException(
        'A resposta de esclarecimento está incompleta.',
        method: 'clarify.lock',
      );
    }
    final result = await _client.call('clarify.lock', {
      'request_id': requestId,
      'question_id': questionId,
      'answer': normalized,
    });
    final remaining = result['remaining'];
    return ClarifyResponse(
      expired: result['status'] == 'expired',
      remaining: remaining is List
          ? List<String>.unmodifiable(
              remaining
                  .whereType<String>()
                  .map((id) => id.trim())
                  .where((id) => id.isNotEmpty),
            )
          : null,
    );
  }

  static Object? _clarifyAnswer(Object answer) {
    if (answer is String) {
      final trimmed = answer.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (answer is List) {
      final values = answer
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      return values.isEmpty || values.length != answer.length ? null : values;
    }
    return null;
  }

  static String? _clarifyAnswerWire(Object answer) {
    final normalized = _clarifyAnswer(answer);
    if (normalized is List<String>) return jsonEncode(normalized);
    return normalized as String?;
  }

  @override
  Future<List<SessionMessage>> refreshHistory() async {
    final result = await _client.call('session.history', {
      'session_id': liveSessionId,
    });
    return DashboardGatewayRepository._historyFrom(result);
  }

  @override
  Future<void> close() => _client.close();

  static Iterable<RunEvent> _eventsFrom(
    GatewayFrame frame,
    String turnId,
  ) sync* {
    if (frame is GatewayServerRequestFrame) {
      switch (frame.method) {
        case 'clarify':
          final request = ClarifyRequest.fromGateway({
            ...frame.params,
            'request_id': frame.id,
          });
          if (request.isValid) yield RunEvent.clarifyRequest(request);
        case 'approval':
          final request = ApprovalRequest.fromEvent({
            ...frame.params,
            'run_id': turnId,
            'request_id': frame.id,
            'server_request': true,
          });
          yield RunEvent.approvalRequest(request);
      }
      return;
    }
    if (frame is! GatewayEventFrame) return;
    final type = frame.type;
    final payload = frame.payload;
    if (!knownGatewayEvents.contains(type)) {
      yield RunEvent.unknown(type, payload);
      return;
    }

    switch (type) {
      case 'gateway.ready':
        break;
      case 'message.start':
        yield const RunEvent.status(RunStatus.running);
      case 'message.delta':
        final text = _rawEventText(payload);
        if (text.isNotEmpty) yield RunEvent.delta(text);
      case 'message.complete':
        final status = payload['status']?.toString().toLowerCase();
        switch (status) {
          // Mirrors de subagent ainda mandam só `text`: o evento já é a
          // fronteira terminal. `completed` é o que gateways antigos emitiam.
          case null:
          case 'complete':
          case 'completed':
            yield RunEvent.completed(output: _rawEventText(payload));
          case 'error':
          case 'failed':
            yield RunEvent.failed(error: _completionFailure(payload));
          case 'interrupted':
            yield const RunEvent.status(RunStatus.cancelled);
          default:
            // Status futuro não é sucesso (o texto pode ser parcial), mas
            // também não pode deixar o turno aberto: fecha como falha.
            yield RunEvent.failed(error: _completionFailure(payload));
        }
      case 'reasoning.delta':
        final text = _rawEventText(payload);
        if (text.isNotEmpty) yield RunEvent.reasoningDelta(text);
      // Estado de execução, não conteúdo. Texto vazio é o sinal de limpeza que
      // o gateway manda, então ele **precisa** passar: descartá-lo deixava o
      // kaomoji preso na tela.
      case 'thinking.delta':
        yield RunEvent.thinkingState(_rawEventText(payload).trim());
      // Medido em 2026-08-15: no TUI este evento traz a resposta final
      // truncada (501 caracteres contra 716 do `message.complete`), e na Runs
      // traz a resposta final inteira. Nos dois casos vira duplicata do corpo
      // da mensagem, então não vira bloco de atividade em lugar nenhum.
      case 'reasoning.available':
        break;
      case 'status.update':
      case 'tool.generating':
      case 'background.complete':
      case 'review.summary':
      case 'subagent.thinking':
      case 'subagent.progress':
        final text = _eventText(payload);
        if (text.isNotEmpty) yield RunEvent.activityPreview(text);
      case 'tool.start':
        final name = payload['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          final args = _argsJson(payload['args']);
          yield RunEvent.toolProgress(
            ToolCall(
              id: _textOrNull(payload['tool_id']),
              name: name,
              // `context` é a prévia que o próprio servidor calculou, já
              // passada pelo redator dele. Só na ausência dela o app resume os
              // `args` por conta própria, com a mesma regra do histórico.
              arg:
                  _textOrNull(payload['context']) ??
                  _textOrNull(payload['args_text']) ??
                  toolPreview(name, args),
              detail: _textOrNull(toolDetail(name, args)),
            ),
          );
        }
      case 'tool.complete':
        final name = payload['name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          final args = _argsJson(payload['args']);
          final failure = _toolFailure(payload['result']);
          yield RunEvent.toolProgress(
            ToolCall(
              id: _textOrNull(payload['tool_id']),
              name: name,
              detail: _textOrNull(toolDetail(name, args)),
              // `result` é o resultado inteiro, o mesmo texto que o histórico
              // guarda como `content` do `role: tool`. Ler só o `summary`
              // deixava o card ao vivo com 22 caracteres onde a conversa
              // reaberta tinha 44.019. `inline_diff` tem precedência porque é
              // o próprio resultado já renderizado para exibição.
              output:
                  _textOrNull(payload['inline_diff']) ??
                  _resultText(payload['result']) ??
                  _textOrNull(payload['summary']),
              duration: _textOrNull(payload['duration_s']),
              status: failure == null ? ToolStatus.done : ToolStatus.error,
            ),
          );
        }
      case 'approval.request':
        final augmented = <String, dynamic>{...payload, 'run_id': turnId};
        if (augmented['choices'] is! List) {
          augmented['choices'] = [
            'once',
            if (payload['allow_permanent'] == true) 'always',
            'deny',
          ];
        }
        final request = ApprovalRequest.fromEvent(augmented);
        if (request.command.isNotEmpty) {
          yield RunEvent.approvalRequest(request);
        }
      case 'secret.request':
        yield const RunEvent.activityPreview(
          'O Desktop precisa responder a um pedido de segredo.',
        );
      case 'sudo.request':
        yield const RunEvent.activityPreview(
          'O Desktop precisa responder a um pedido de privilégio.',
        );
      default:
        yield RunEvent.unknown(type, payload);
    }
  }

  static String _eventText(Map<String, dynamic> payload) =>
      _textOrNull(
        payload['text'] ??
            payload['preview'] ??
            payload['summary'] ??
            payload['message'],
      ) ??
      '';

  static String? _completionFailure(Map<String, dynamic> payload) =>
      _textOrNull(payload['failure_reason']) ??
      _textOrNull(payload['error']) ??
      _textOrNull(_eventText(payload));

  static String _rawEventText(Map<String, dynamic> payload) =>
      (payload['text'] ?? payload['rendered'] ?? '').toString();

  /// Devolve os `args` do evento como o mesmo JSON cru que o histórico guarda
  /// em `tool_calls[].function.arguments`, para que a prévia e o detalhe sejam
  /// calculados pela **mesma** regra nos dois caminhos. Ver `tool_preview.dart`:
  /// é lá que mora a restrição de só expor argumento cru de `terminal` e
  /// `execute_code`, porque o app não tem o redator de segredos do servidor.
  static String _argsJson(Object? args) {
    if (args == null) return '';
    if (args is String) return args;
    try {
      return jsonEncode(args);
    } catch (_) {
      return '';
    }
  }

  /// Reconstitui o texto do resultado. O gateway desserializa o resultado antes
  /// de emitir (`json.loads` em `_on_tool_complete`), então aqui ele volta a ser
  /// texto para casar com o `content` do `role: tool` no histórico.
  static String? _resultText(Object? result) {
    if (result == null) return null;
    if (result is String) return _textOrNull(result);
    try {
      return _textOrNull(jsonEncode(result));
    } catch (_) {
      return _textOrNull(result.toString());
    }
  }

  /// `tool.complete` **não tem campo `error`**, medido no `0.20.1`. Procurar
  /// `payload['error']` fazia toda ferramenta que falhou aparecer como
  /// concluída. O que existe é a convenção de resultado do próprio Hermes,
  /// `{"success": false, "error": "..."}`.
  static String? _toolFailure(Object? result) {
    if (result is! Map) return null;
    final error = _textOrNull(result['error']);
    if (result['success'] == false) return error ?? 'A ferramenta falhou.';
    return error;
  }

  static String? _textOrNull(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}

final class _GatewaySocketClient {
  _GatewaySocketClient(
    this._socket, {
    required this.heartbeatInterval,
    required this.heartbeatDeadline,
  }) {
    _events = StreamController<GatewayFrame>.broadcast(
      sync: true,
      onListen: _scheduleDrain,
    );
    _subscription = _socket.stream.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
      cancelOnError: false,
    );
  }

  final GatewaySocket _socket;
  final Duration heartbeatInterval;
  final Duration heartbeatDeadline;
  late final StreamSubscription<dynamic> _subscription;
  final _ready = Completer<void>();
  final _pending = <String, _PendingCall>{};
  // Broadcast evita que o teardown espere por um listener que nunca chegou.
  // O buffer manual preserva frames pré-listener sem deixar `close()` pendurado.
  late final StreamController<GatewayFrame> _events;
  final _queuedEvents = <GatewayFrame>[];
  final _queuedUnboundRequests = <GatewayServerRequestFrame>[];
  String? _sessionId;
  var _seed = 0;
  var _receivedFirstFrame = false;
  var _capabilitiesAdvertised = false;
  var _closed = false;
  var _failed = false;
  Timer? _heartbeatTimer;
  DateTime _lastLivenessAt = DateTime.now();
  var _heartbeatInFlight = false;
  var _drainScheduled = false;

  Future<void> get ready => _ready.future;
  Stream<GatewayFrame> get events => _events.stream;

  void bindSessionId(String sessionId) {
    _sessionId = sessionId.trim();
    final pending = List<GatewayServerRequestFrame>.from(
      _queuedUnboundRequests,
    );
    _queuedUnboundRequests.clear();
    for (final frame in pending) {
      _handleServerRequest(frame);
    }
  }

  /// Drenar dentro do `onListen` entregaria os frames durante o `listen()`,
  /// antes de o operador de stream do turno (`asyncExpand`) terminar de
  /// assinar: o evento se perdia. Um microtask adia para depois da assinatura.
  void _scheduleDrain() {
    if (_drainScheduled) return;
    _drainScheduled = true;
    scheduleMicrotask(() {
      _drainScheduled = false;
      _drainQueuedEvents();
    });
  }

  void _drainQueuedEvents() {
    while (_queuedEvents.isNotEmpty &&
        _events.hasListener &&
        !_events.isClosed) {
      _events.add(_queuedEvents.removeAt(0));
    }
  }

  void _publishEvent(GatewayFrame frame) {
    if (_events.isClosed) return;
    // Com fila pendente, o frame novo entra atrás dela para manter a ordem.
    if (_events.hasListener && _queuedEvents.isEmpty) {
      _events.add(frame);
      return;
    }
    _queuedEvents.add(frame);
    if (_events.hasListener) _scheduleDrain();
  }

  Future<Map<String, dynamic>> call(
    String method,
    Map<String, dynamic> params, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!allowedGatewayMethods.contains(method)) {
      throw GatewayOperationException(
        'Método não permitido pelo cliente móvel: $method.',
        method: method,
      );
    }
    // Uma conexão preparada pode ter morrido enquanto a pessoa escrevia. Falhar
    // agora, sem código, é o que marca a falha como transitória e leva a nova
    // tentativa a abrir outro socket em vez de esperar o timeout.
    if (_closed || _failed) {
      throw GatewayOperationException(
        'O canal do gateway foi encerrado.',
        method: method,
      );
    }
    final id = 'mobile-${++_seed}';
    final pending = _PendingCall(method);
    _pending[id] = pending;
    turnCapture.outgoing(method, params);
    _socket.add(encodeGatewayRequest(id: id, method: method, params: params));
    return pending.completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('RPC $method expirou.');
      },
    );
  }

  /// Responde a um pedido server→client usando o id do envelope original.
  /// Não passa pelo mapa de chamadas locais: este id pertence ao servidor.
  ///
  /// Falha em voz alta: engolir a resposta deixaria a UI achando que o servidor
  /// recebeu uma escolha que nunca saiu do aparelho.
  void respondToServerRequest(String id, Map<String, dynamic> result) {
    if (id.isEmpty || _closed || _failed) {
      throw const GatewayOperationException(
        'O canal do gateway foi encerrado.',
      );
    }
    _socket.add(jsonEncode({'jsonrpc': '2.0', 'id': id, 'result': result}));
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    final GatewayFrame frame;
    try {
      frame = decodeGatewayFrame(raw);
    } on GatewayProtocolException catch (error, stackTrace) {
      _onError(GatewayOperationException(error.message), stackTrace);
      return;
    }
    if (!_receivedFirstFrame) {
      _receivedFirstFrame = true;
      if (frame is! GatewayEventFrame || frame.type != 'gateway.ready') {
        _onError(
          const GatewayOperationException(
            'O primeiro frame do gateway não foi gateway.ready.',
          ),
          StackTrace.current,
        );
        return;
      }
    }
    // O contrato Desktop considera qualquer frame recebido como prova de
    // vida; o `gateway.ping` é apenas o keepalive que detecta silêncio.
    _lastLivenessAt = DateTime.now();
    switch (frame) {
      case GatewayEventFrame(:final type, :final payload):
        turnCapture.rawFrame(type, payload);
        if (type == 'gateway.ready') {
          if (!_ready.isCompleted) _ready.complete();
          if (payload['heartbeat'] == true) _startHeartbeat();
          if (!_capabilitiesAdvertised) {
            _capabilitiesAdvertised = true;
            // Older gateways answer -32601; that response is intentionally
            // ignored (o `call` já registra o erro no turnCapture). Anunciar
            // vale em todo socket novo.
            unawaited(
              call('client.capabilities', const {
                'server_requests': true,
              }).catchError((Object _) => <String, dynamic>{}),
            );
          }
        }
        // `gateway.ready` is transport lifecycle, not a run event. Replay only
        // the frames that belong to the live turn.
        if (type != 'gateway.ready') _publishEvent(frame);
      case GatewayServerRequestFrame(:final id, :final method, :final params):
        _handleServerRequest(
          GatewayServerRequestFrame(id: id, method: method, params: params),
        );
      case GatewayResultFrame(:final id, :final result):
        final pending = _pending.remove(id);
        if (pending == null) return;
        _deliverOpenRequests(result);
        turnCapture.rpcResult(
          pending.method,
          result is Map<String, dynamic> ? result : const <String, dynamic>{},
        );
        pending.completer.complete(
          result is Map<String, dynamic> ? result : <String, dynamic>{},
        );
      case GatewayErrorFrame(:final id, :final code, :final message):
        final pending = _pending.remove(id);
        if (pending == null) return;
        turnCapture.rpcError(pending.method, code, message);
        pending.completer.completeError(
          gatewayRpcFailure(
            method: pending.method,
            code: code,
            message: message,
          ),
        );
    }
  }

  /// Espelha `WINDOW_OWNED_REQUESTS` do Desktop
  /// (`apps/desktop/.../gateway-event/server-requests.ts`).
  static const _windowOwnedRequests = {
    'preview.act',
    'preview.read',
    'terminal.read',
    'window.read',
    'tour',
  };

  void _handleServerRequest(GatewayServerRequestFrame frame) {
    if (_sessionId == null || _sessionId!.isEmpty) {
      _queuedUnboundRequests.add(frame);
      return;
    }
    final requestSessionId = frame.params['session_id'];
    if (requestSessionId is! String || requestSessionId != _sessionId) {
      _respondServerError(frame.id, -32602, 'server request session mismatch');
      return;
    }
    // Pedidos de janela do Desktop: o gateway guarda a PRIMEIRA resposta, então
    // um -32601 instantâneo daqui derrubaria o pedido antes da janela dona
    // responder. `4404` é o voto "não estou mostrando esta sessão", que deixa o
    // pedido aberto até todos os clientes recusarem
    // (`tui_gateway/server_requests.py::_decline`, `NOT_SHOWN_CODE`).
    if (_windowOwnedRequests.contains(frame.method)) {
      _respondServerError(frame.id, 4404, 'not shown in the mobile client');
      return;
    }
    // Mobile intentionally supports only the two safe interactive cards.
    // Sudo, secret and vault are rejected without ever entering the UI or
    // diagnostics capture, como o Desktop faz com método sem handler.
    if (frame.method != 'clarify' && frame.method != 'approval') {
      _respondServerError(
        frame.id,
        -32601,
        'mobile client does not handle ${frame.method}',
      );
      return;
    }
    if (frame.method == 'clarify') {
      final request = ClarifyRequest.fromGateway({
        ...frame.params,
        'request_id': frame.id,
      });
      if (!request.isValid) {
        _respondServerError(
          frame.id,
          -32602,
          'unsupported clarify request shape',
        );
        return;
      }
    }
    if (frame.method == 'approval' &&
        (frame.params['request_id'] is! String ||
            (frame.params['request_id'] as String).isEmpty)) {
      _respondServerError(
        frame.id,
        -32602,
        'unsupported approval request shape',
      );
      return;
    }
    _publishEvent(frame);
  }

  void _deliverOpenRequests(Object? rawResult) {
    if (rawResult is! Map<String, dynamic>) return;
    final rawOpen = rawResult['open_requests'];
    if (rawOpen is! List) return;
    for (final raw in rawOpen) {
      if (raw is! Map) continue;
      final id = raw['id'];
      final method = raw['method'];
      final rawParams = raw['params'];
      if (id is! String || id.isEmpty || method is! String || method.isEmpty) {
        continue;
      }
      final params = rawParams is Map
          ? rawParams.map((key, value) => MapEntry(key.toString(), value))
          : const <String, dynamic>{};
      _handleServerRequest(
        GatewayServerRequestFrame(id: id, method: method, params: params),
      );
    }
  }

  void _respondServerError(String id, int code, String message) {
    if (_closed || _failed) return;
    _socket.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': message},
      }),
    );
  }

  void _onError(Object error, StackTrace stackTrace) {
    if (_closed || _failed) return;
    _failed = true;
    final failure = switch (error) {
      GatewayAuthenticationRequired() => error,
      GatewayOperationException() => error,
      _ => const GatewayOperationException('O canal do gateway falhou.'),
    };
    if (!_ready.isCompleted) _ready.completeError(failure, stackTrace);
    for (final pending in _pending.values) {
      pending.completer.completeError(failure, stackTrace);
    }
    _pending.clear();
    if (!_events.isClosed) _events.addError(failure, stackTrace);
  }

  void _onDone() {
    if (_socket.closeCode == 4401) {
      _onError(
        const GatewayAuthenticationRequired(
          'O ticket do gateway expirou. Tente enviar novamente.',
        ),
        StackTrace.current,
      );
      return;
    }
    _onError(
      GatewayOperationException(
        _socket.closeCode == 4403
            ? 'O gateway recusou o host ou a origem do aparelho.'
            : 'O canal do gateway foi encerrado.',
      ),
      StackTrace.current,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    // O contrato pede uma resposta por id: pedidos que chegaram antes de a
    // sessão ser vinculada não podem ficar pendurados no servidor.
    for (final frame in List.of(_queuedUnboundRequests)) {
      _respondServerError(frame.id, -32603, 'mobile session was not bound');
    }
    _closed = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _queuedEvents.clear();
    _queuedUnboundRequests.clear();
    await _subscription.cancel();
    if (!_events.isClosed) await _events.close();
    await _socket.close();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _lastLivenessAt = DateTime.now();
    if (heartbeatInterval <= Duration.zero ||
        heartbeatDeadline <= Duration.zero) {
      return;
    }
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (_closed || _failed) return;
      if (DateTime.now().difference(_lastLivenessAt) >= heartbeatDeadline) {
        _failHeartbeat();
        return;
      }
      unawaited(_sendHeartbeat());
    });
  }

  Future<void> _sendHeartbeat() async {
    if (_heartbeatInFlight) return;
    _heartbeatInFlight = true;
    try {
      await call('gateway.ping', const {}, timeout: heartbeatDeadline);
    } catch (_) {
      if (!_closed &&
          DateTime.now().difference(_lastLivenessAt) >= heartbeatDeadline) {
        _failHeartbeat();
      }
    } finally {
      _heartbeatInFlight = false;
    }
  }

  void _failHeartbeat() {
    if (_closed || _failed) return;
    _onError(
      const GatewayOperationException(
        'O canal do gateway ficou sem resposta e foi encerrado.',
        method: 'gateway.ping',
      ),
      StackTrace.current,
    );
    // A falha de liveness não pode deixar o socket e o timer vivos esperando
    // um `onDone` que proxies silenciosos nunca enviam.
    unawaited(close());
  }
}

/// Chamada RPC em voo. Guardar o método é o que permite dizer qual operação
/// falhou quando o gateway responde com um erro genérico.
final class _PendingCall {
  _PendingCall(this.method);

  final String method;
  final completer = Completer<Map<String, dynamic>>();
}
