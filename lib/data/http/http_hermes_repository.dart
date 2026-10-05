import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'hermes_api_exception.dart';

import '../../core/diagnostics/turn_capture.dart';
import '../../domain/models/capabilities.dart';
import '../../domain/models/approval_request.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/conversation_page.dart';
import '../../domain/models/health_status.dart';
import '../../domain/models/hermes_failure.dart';
import '../../domain/models/hermes_model.dart';
import '../../domain/models/hermes_skill.dart';
import '../../domain/models/hermes_toolset.dart';
import '../../domain/models/model_lock.dart';
import '../../domain/models/model_options.dart';
import '../../domain/models/run.dart';
import '../../domain/models/run_event.dart';
import '../../domain/models/session_message.dart';
import '../../domain/models/tool_call.dart';
import '../../domain/repositories/hermes_repository.dart';

/// Adapter REAL do [HermesRepository]: fala com a Hermes API via `dio` + SSE.
///
/// Num app nativo NÃO há a limitação de `Authorization` do `EventSource` do
/// browser: mandamos o header direto no GET do stream.
class HttpHermesRepository implements HermesRepository {
  HttpHermesRepository({
    String baseUrl = 'http://localhost:8642',
    required String apiKey,
    Dio? dio,
    this.prazo = const Duration(seconds: 30),
  }) : _dio = _withSafeErrors(
         dio ??
             Dio(
               BaseOptions(
                 baseUrl: baseUrl,
                 headers: {
                   'Authorization': 'Bearer $apiKey',
                   'Content-Type': 'application/json',
                 },
                 // Medido no emulador ao verificar o A7: sem isto, cortar a rede
                 // deixava a lista girando **para sempre**, porque o `dio` nasce
                 // sem timeout e o TCP do sistema demora minutos a desistir. Um
                 // spinner eterno é o pior estado offline possível: não diz nada e
                 // não deixa agir.
                 connectTimeout: const Duration(seconds: 12),
                 sendTimeout: const Duration(seconds: 20),
                 receiveTimeout: const Duration(seconds: 30),
               ),
             ),
       );

  final Dio _dio;

  /// Prazo total de uma chamada, contado no app.
  ///
  /// Não é redundante com o `connectTimeout` do `dio`: medido no emulador com a
  /// rede desligada, aquele limite **não** cobre tudo (a resolução de nome fica
  /// de fora), e é justamente aí que a chamada ficava presa. A lista girava sem
  /// fim, que é o pior estado offline possível: não diz nada e não deixa agir.
  /// Ver A7.
  final Duration prazo;

  /// Só para teste: os limites de tempo com que o cliente foi montado.
  BaseOptions get debugOptions => _dio.options;

  static Dio _withSafeErrors(Dio dio) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final envelope = _map(error.response?.data);
          final publicError = _map(envelope?['error']);
          handler.reject(
            DioException(
              requestOptions: RequestOptions(
                path: error.requestOptions.path,
                method: error.requestOptions.method,
              ),
              type: error.type,
              error: HermesApiException(
                statusCode: error.response?.statusCode,
                message: publicError?['message']?.toString(),
                type: publicError?['type']?.toString(),
                code: publicError?['code']?.toString(),
              ),
            ),
          );
        },
      ),
    );
    return dio;
  }

  /// Toda chamada sai por aqui, e o erro sai traduzido.
  ///
  /// A conversão tem de acontecer na **saída** do adapter, e não no
  /// interceptor: interceptor do `dio` só sabe rejeitar com `DioException`, e é
  /// exatamente a `DioException` que não pode chegar em `lib/features/`. Antes
  /// disto a tela imprimia `'$error'`, ou seja o `toString` inteiro da
  /// `DioException`, no lugar onde deveria estar a causa. Ver A7.
  Future<T> _traduzindo<T>(Future<T> Function() chamada) async {
    try {
      return await chamada().timeout(prazo);
    } on TimeoutException {
      throw const HermesFailure(HermesFailureKind.tempoEsgotado);
    } on DioException catch (error) {
      throw failureFromDio(error);
    }
  }

  Future<Response<T>> _get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _traduzindo(
    () => _dio.get<T>(path, queryParameters: queryParameters, options: options),
  );

  Future<Response<T>> _post<T>(String path, {Object? data}) =>
      _traduzindo(() => _dio.post<T>(path, data: data));

  Future<Response<T>> _patch<T>(String path, {Object? data}) =>
      _traduzindo(() => _dio.patch<T>(path, data: data));

  Future<Response<T>> _delete<T>(String path) =>
      _traduzindo(() => _dio.delete<T>(path));

  @override
  Future<HealthStatus> health() async {
    final res = await _get<Map<String, dynamic>>('/health');
    return HealthStatus.fromJson(res.data ?? const {});
  }

  @override
  Future<Capabilities> capabilities() async {
    final res = await _get<Map<String, dynamic>>('/v1/capabilities');
    return Capabilities.fromJson(res.data ?? const {});
  }

  @override
  Future<List<HermesModel>> models() async {
    final res = await _get<Map<String, dynamic>>('/v1/models');
    // shape OpenAI: { object: 'list', data: [ {id, ...}, ... ] }
    final data = (res.data?['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(HermesModel.fromJson)
        .toList();
    return data;
  }

  /// Inventário de providers e modelos.
  ///
  /// `GET /api/model/options` vive **no próprio API Server**, registrado ao lado
  /// de `/v1/models` (`gateway/platforms/api_server.py`), e exige a mesma chave.
  /// A versão anterior montava um `Dio` novo apontando para
  /// `http://<host>:3000`, sem chave e em cleartext, e engolia o `DioException`:
  /// o inventário nunca chegava e a tela dizia que o gateway não anunciava
  /// providers. O payload é `{providers, model, provider}`.
  ///
  /// A rota do API Server aceita só `refresh`; ela sempre inclui providers não
  /// configurados, e o `explicit_only` que mandávamos antes não é lido aqui.
  @override
  Future<ModelOptions> modelOptions({bool refresh = false}) async {
    final res = await _get<Map<String, dynamic>>(
      '/api/model/options',
      queryParameters: refresh ? const {'refresh': true} : null,
    );
    return ModelOptions.fromJson(res.data ?? const {});
  }

  @override
  Future<List<HermesSkill>> skills() async {
    final res = await _get<Map<String, dynamic>>('/v1/skills');
    return _dataList(
      res.data,
    ).map(HermesSkill.fromJson).toList(growable: false);
  }

  @override
  Future<List<HermesToolset>> toolsets() async {
    final res = await _get<Map<String, dynamic>>('/v1/toolsets');
    return _dataList(
      res.data,
    ).map(HermesToolset.fromJson).toList(growable: false);
  }

  @override
  Future<List<Conversation>> listConversations({int limit = 100}) async {
    return (await conversationPage(limit: limit)).items;
  }

  @override
  Future<ConversationPage> conversationPage({
    int limit = 50,
    int offset = 0,
    String? source,
  }) async {
    final res = await _get<Map<String, dynamic>>(
      '/api/sessions',
      queryParameters: {
        'limit': limit,
        'offset': offset,
        'source': ?source,
        'include_children': true,
      },
    );
    final body = res.data ?? const <String, dynamic>{};
    return ConversationPage(
      items: _dataList(body).map(_conversationFromJson).toList(growable: false),
      limit: (body['limit'] as num?)?.toInt() ?? limit,
      offset: (body['offset'] as num?)?.toInt() ?? offset,
      hasMore: body['has_more'] as bool? ?? false,
    );
  }

  @override
  Future<Conversation> getConversation(String sessionId) async {
    final res = await _get<Map<String, dynamic>>(
      '/api/sessions/${Uri.encodeComponent(sessionId)}',
    );
    final session = _map(res.data?['session']);
    if (session == null) {
      throw StateError('O Hermes não devolveu os detalhes da sessão.');
    }
    return _conversationFromJson(session);
  }

  @override
  Future<Conversation> createConversation({
    String? title,
    String? model,
    String? provider,
  }) async {
    final res = await _post<Map<String, dynamic>>(
      '/api/sessions',
      data: {'title': ?title, 'model': ?model, 'provider': ?provider},
    );
    final session = _map(res.data?['session']);
    if (session == null) {
      throw StateError('O Hermes não devolveu a sessão criada.');
    }
    return _conversationFromJson(session);
  }

  @override
  Future<List<SessionMessage>> conversationMessages(String sessionId) async {
    final res = await _get<Map<String, dynamic>>(
      '/api/sessions/${Uri.encodeComponent(sessionId)}/messages',
    );
    return _dataList(
      res.data,
    ).map(_sessionMessageFromJson).toList(growable: false);
  }

  @override
  Future<Conversation> updateConversation(
    String sessionId, {
    String? title,
  }) async {
    final res = await _patch<Map<String, dynamic>>(
      '/api/sessions/${Uri.encodeComponent(sessionId)}',
      data: {'title': ?title},
    );
    final session = _map(res.data?['session']);
    if (session == null) {
      throw StateError('O Hermes não devolveu a sessão atualizada.');
    }
    return _conversationFromJson(session);
  }

  @override
  Future<Conversation> forkConversation(
    String sessionId, {
    String? title,
  }) async {
    final res = await _post<Map<String, dynamic>>(
      '/api/sessions/${Uri.encodeComponent(sessionId)}/fork',
      data: {'title': ?title},
    );
    final session = _map(res.data?['session']);
    if (session == null) {
      throw StateError('O Hermes não devolveu a conversa ramificada.');
    }
    return _conversationFromJson(session);
  }

  @override
  Future<void> deleteConversation(String sessionId) async {
    await _delete<void>('/api/sessions/${Uri.encodeComponent(sessionId)}');
  }

  /// `POST /api/sessions/{id}/model`, o "browser model lock" do Hermes.
  ///
  /// O handler força `require_model_lock`, então o corpo é só o par pedido. A
  /// resposta é `{object, session_id, runtime}`, e é o `runtime` que diz o que
  /// ficou valendo: o servidor pode resolver o provider por rota e devolver um
  /// par diferente do pedido.
  @override
  Future<ModelLock> lockConversationModel(
    String sessionId,
    ModelLock lock,
  ) async {
    final Response<Map<String, dynamic>> res;
    try {
      res = await _post<Map<String, dynamic>>(
        '/api/sessions/${Uri.encodeComponent(sessionId)}/model',
        data: lock.toRequest(),
      );
    } on HermesFailure catch (falha) {
      // A recusa é traduzida aqui, e não no controller: `lib/features/` fala com
      // o port e não deve conhecer `dio` nem código de status HTTP.
      throw ModelLockException(
        failure: modelLockFailureFrom(
          statusCode: falha.statusCode,
          code: falha.code,
        ),
        requested: lock,
      );
    }

    final runtime = _map(res.data?['runtime']);
    if (runtime == null) {
      throw ModelLockException(
        failure: ModelLockFailure.falhaDoServidor,
        requested: lock,
      );
    }
    final confirmado = ModelLock.fromRuntime(runtime);
    // Sem modelo no runtime não há o que confirmar; devolver o pedido seria
    // afirmar que deu certo sem prova.
    return confirmado.model.isEmpty ? lock : confirmado;
  }

  @override
  Future<Run> createRun({
    required String input,
    String? sessionId,
    String? instructions,
    String? model,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    final res = await _post<Map<String, dynamic>>(
      '/v1/runs',
      data: {
        'input': input,
        'session_id': ?sessionId,
        'instructions': ?instructions,
        'model': ?model,
        'conversation_history': ?conversationHistory,
      },
    );
    return Run.fromJson(res.data ?? const {});
  }

  @override
  Future<Run> getRun(String runId) async {
    final res = await _get<Map<String, dynamic>>('/v1/runs/$runId');
    return Run.fromJson(res.data ?? {'run_id': runId});
  }

  @override
  Future<Run> stopRun(String runId) async {
    final res = await _post<Map<String, dynamic>>(
      '/v1/runs/$runId/stop',
      data: {},
    );
    // resposta documentada: {"status": "stopping"} - sem run_id, então
    // reconstruímos o Run com o id que já temos.
    final status = res.data?['status'];
    return Run(
      runId: runId,
      status: status is String ? parseStatus(status) : RunStatus.stopping,
    );
  }

  /// `POST /v1/runs/{id}/approval` com `{choice}`.
  ///
  /// O servidor normaliza `approve`/`approved`/`allow` para `once`, mas mandamos
  /// o valor canônico. Não enviamos `all`: resolver todas as pendências de uma
  /// vez é uma concessão maior do que o gesto na tela representa.
  @override
  Future<void> respondToApproval(String runId, ApprovalChoice choice) async {
    try {
      await _post<Map<String, dynamic>>(
        '/v1/runs/$runId/approval',
        data: {'choice': choice.wireValue},
      );
    } on HermesFailure catch (falha) {
      // Traduzido aqui para `lib/features/` não precisar conhecer `dio`.
      throw ApprovalException(
        approvalFailureFrom(statusCode: falha.statusCode, code: falha.code),
      );
    }
  }

  @override
  Stream<RunEvent> runEvents(String runId) async* {
    late final Response<ResponseBody> res;
    try {
      res = await _get<ResponseBody>(
        '/v1/runs/$runId/events',
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
          // O stream da run é a **exceção** ao timeout de recepção: entre um
          // evento e outro o agente pode ficar minutos pensando ou rodando uma
          // ferramenta, e cortar ali mataria a resposta no meio. `Duration.zero`
          // desliga só este limite; o de conexão continua valendo.
          receiveTimeout: Duration.zero,
        ),
      );
    } catch (error) {
      // Falhar ao abrir ou reabrir o canal não significa que a execução falhou.
      // O controller precisa receber a falha de transporte para reconciliar o
      // snapshot/histórico; transformar um 404 daqui em `run.failed` fazia uma
      // retomada obsoleta aparecer como resposta "Não encontrado".
      throw hermesFailureFrom(error);
    }

    final body = res.data;
    if (body == null) {
      throw const HermesFailure(HermesFailureKind.respostaInesperada);
    }

    var buffer = '';
    String? currentEvent;
    final dataLines = <String>[];

    try {
      // Cada linha em branco fecha um "frame" SSE.
      await for (final chunk in body.stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        var idx = buffer.indexOf('\n');
        while (idx >= 0) {
          final line = buffer.substring(0, idx).replaceAll('\r', '');
          buffer = buffer.substring(idx + 1);

          if (line.isEmpty) {
            // fim de um frame -> despacha
            if (dataLines.isNotEmpty || currentEvent != null) {
              final frame = dataLines.join('\n');
              turnCapture.rawSse(currentEvent, frame);
              final event = parseSse(currentEvent, frame);
              if (event != null) yield event;
              if (event is RunCompleted || event is RunFailed) return;
            }
            currentEvent = null;
            dataLines.clear();
          } else if (line.startsWith(':')) {
            // comentário SSE (keep-alive) - ignora
          } else if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            dataLines.add(line.substring(5).trimLeft());
          }
          idx = buffer.indexOf('\n');
        }
      }
    } on DioException catch (error) {
      // Depois que os headers chegaram, o corpo ainda pode cair por troca de
      // rede, suspensão do app ou socket encerrado. Antes isto escapava cru e a
      // feature chamava uma queda de transporte de "resposta inesperada".
      throw failureFromDio(error);
    } on HermesFailure {
      rethrow;
    } catch (_) {
      // Dentro deste bloco o parser é tolerante e não lança; uma exceção sem
      // tipo do Dio vem do byte stream subjacente e tem semântica de transporte.
      throw const HermesFailure(HermesFailureKind.semRede);
    }
  }

  // --- parsing --------------------------------------------------------------

  /// Interpreta um frame SSE (`event:` + `data:`) num [RunEvent].
  ///
  /// Mapeia somente os eventos emitidos pela Runs API. O envelope real pode
  /// trazer o tipo em `event` dentro de `data:`, sem uma linha `event:` SSE.
  static RunEvent? parseSse(String? event, String data) {
    final trimmed = data.trim();
    if (trimmed.isEmpty && (event == null || event.isEmpty)) return null;
    if (trimmed == '[DONE]') return const RunEvent.completed();

    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // data não-JSON
    }

    final type = (event ?? json?['event'] ?? json?['type'] ?? '')
        .toString()
        .toLowerCase();

    switch (type) {
      case 'message.delta':
        final text = _extractText(json);
        return text == null
            ? RunEvent.unknown(type, json ?? const {})
            : RunEvent.delta(text);
      case 'tool.started':
      case 'tool.completed':
        final tool = _toolFromJson(json, eventType: type);
        return tool == null
            ? RunEvent.unknown(type, json ?? const {})
            : RunEvent.toolProgress(tool);
      // Medido em 2026-08-15: aqui o texto vem **idêntico** ao `output` do
      // `run.completed`, então virar bloco de atividade fazia a resposta
      // inteira aparecer duas vezes na timeline ao vivo. No TUI o mesmo evento
      // traz a resposta truncada, e o efeito era o mesmo.
      case 'reasoning.available':
        return RunEvent.unknown(type, json ?? const {});
      // O comando já chega redigido pelo servidor; o app não reconstrói nada.
      case 'approval.request':
        if (json == null) return RunEvent.unknown(type, const {});
        return RunEvent.approvalRequest(ApprovalRequest.fromEvent(json));
      case 'approval.responded':
        final choice = approvalChoiceFrom(json?['choice']?.toString());
        return choice == null
            ? RunEvent.unknown(type, json ?? const {})
            : RunEvent.approvalResolved(choice);
      case 'run.completed':
        return RunEvent.completed(output: json?['output']?.toString());
      case 'run.failed':
        return RunEvent.failed(
          error: (json?['error'] ?? json?['message'])?.toString(),
        );
      case 'run.cancelled':
      case 'run.canceled':
        return const RunEvent.status(RunStatus.cancelled);
    }
    return RunEvent.unknown(
      type.isEmpty ? 'unknown' : type,
      json ?? {'data': data},
    );
  }

  static String? _extractText(Map<String, dynamic>? json) {
    if (json == null) return null;
    for (final key in ['delta', 'text', 'content', 'output_text']) {
      final v = json[key];
      if (v is String) return v;
      if (v is Map<String, dynamic> && v['text'] is String) {
        return v['text'] as String;
      }
    }
    return null;
  }

  static ToolCall? _toolFromJson(
    Map<String, dynamic>? json, {
    String eventType = '',
  }) {
    if (json == null) return null;
    final name = (json['name'] ?? json['tool'] ?? json['tool_name'])
        ?.toString();
    if (name == null || name.isEmpty) return null;
    final arg =
        (json['preview'] ??
                json['arg'] ??
                json['arguments'] ??
                json['args'] ??
                json['input'] ??
                '')
            .toString();
    return ToolCall(
      id: (json['tool_call_id'] ?? json['id'])?.toString(),
      name: name,
      arg: arg,
      duration: json['duration']?.toString(),
      status: _toolStatus(
        json['status'],
        eventType: eventType,
        failed: json['error'] == true,
      ),
    );
  }

  static ToolStatus _toolStatus(
    Object? s, {
    String eventType = '',
    bool failed = false,
  }) {
    final v = s?.toString().toLowerCase() ?? '';
    if (failed) return ToolStatus.error;
    if (eventType == 'tool.completed') return ToolStatus.done;
    if (v.contains('done') || v.contains('complete') || v == 'ok') {
      return ToolStatus.done;
    }
    if (v.contains('error') || v.contains('fail')) return ToolStatus.error;
    return ToolStatus.running;
  }

  /// Mapeia a string de status do servidor para [RunStatus] (fallback unknown).
  static RunStatus parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'started':
        return RunStatus.started;
      case 'queued':
        return RunStatus.queued;
      case 'running':
        return RunStatus.running;
      case 'in_progress':
        return RunStatus.inProgress;
      case 'stopping':
        return RunStatus.stopping;
      case 'completed':
        return RunStatus.completed;
      case 'failed':
        return RunStatus.failed;
      case 'cancelled':
      case 'canceled':
        return RunStatus.cancelled;
      default:
        return RunStatus.unknown;
    }
  }

  static List<Map<String, dynamic>> _dataList(Map<String, dynamic>? body) {
    return _objectList(body?['data']);
  }

  /// Objetos de uma lista JSON crua, descartando o que não for objeto.
  static List<Map<String, dynamic>> _objectList(Object? value) {
    return (value as List<dynamic>? ?? const [])
        .map(_map)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic>? _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }
    return null;
  }

  static Conversation _conversationFromJson(Map<String, dynamic> json) {
    return Conversation.fromJson({
      ...json,
      'id': json['id']?.toString() ?? '',
      'title': json['title']?.toString() ?? 'Nova conversa',
      'preview': json['preview']?.toString() ?? '',
      'model': json['model']?.toString(),
      'provider': json['provider']?.toString(),
      'last_active': json['last_active'],
      'started_at': json['started_at'],
      'message_count': json['message_count'] is num ? json['message_count'] : 0,
      'tool_call_count': json['tool_call_count'] is num
          ? json['tool_call_count']
          : 0,
      'input_tokens': json['input_tokens'] is num ? json['input_tokens'] : 0,
      'output_tokens': json['output_tokens'] is num ? json['output_tokens'] : 0,
      'estimated_cost_usd': json['estimated_cost_usd'] is num
          ? json['estimated_cost_usd']
          : null,
      'actual_cost_usd': json['actual_cost_usd'] is num
          ? json['actual_cost_usd']
          : null,
    });
  }

  static SessionMessage _sessionMessageFromJson(Map<String, dynamic> json) {
    return SessionMessage.fromJson({
      ...json,
      'id': json['id']?.toString() ?? '',
      'role': json['role']?.toString() ?? 'assistant',
      'content': json['content']?.toString() ?? '',
      'timestamp': json['timestamp'],
      'reasoning': json['reasoning']?.toString(),
      'reasoning_content': json['reasoning_content']?.toString(),
      'tool_name': json['tool_name']?.toString(),
      'tool_call_id': json['tool_call_id']?.toString(),
      'tool_calls': json['tool_calls'],
      'token_count': json['token_count'] is num ? json['token_count'] : null,
      'finish_reason': json['finish_reason']?.toString(),
    });
  }
}
