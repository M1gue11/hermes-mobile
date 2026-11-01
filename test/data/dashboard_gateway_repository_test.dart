import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/data/config/dashboard_session_store.dart';
import 'package:hermes_mobile/data/gateway/dashboard_gateway_repository.dart';
import 'package:hermes_mobile/domain/models/approval_request.dart';
import 'package:hermes_mobile/domain/models/composer_attachment.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/domain/models/run_event.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';
import 'package:hermes_mobile/domain/models/conversation_timeline.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/hermes_skill.dart';
import 'package:hermes_mobile/domain/repositories/gateway_repository.dart';

void main() {
  for (final changedEpoch in [false, true]) {
    test(
      'snapshot atualiza estado depois de ${changedEpoch ? "restart" : "replay truncado"}',
      () async {
        var resumes = 0;
        final socket = _FakeGatewaySocket(
          readyPayload: const {'replay_epoch': 'process-2'},
          replayResult: {
            'epoch': changedEpoch ? 'process-3' : 'process-2',
            'truncated': !changedEpoch,
            'latest_seq': 800,
            'events': [
              {
                'type': 'message.delta',
                'session_id': 'live-session',
                'seq': 800,
                'payload': {'text': 'missing prefix'},
              },
            ],
          },
          resultFor: (method) => method != 'session.resume'
              ? null
              : {
                  'session_id': 'live-session',
                  'running': ++resumes == 1,
                  'messages': [
                    {'role': 'user', 'text': 'prompt', 'row_id': 1},
                  ],
                  'inflight': {
                    'user': 'prompt',
                    'assistant': resumes == 1 ? 'partial' : 'retained partial',
                    'streaming': resumes == 1,
                    if (resumes > 1) 'error': 'provider failed',
                    if (resumes > 1) 'status': 'error',
                    'recoverable': true,
                  },
                },
          onCall: (method, socket) {
            if (method == 'session.events.since') {
              socket.emit(
                'message.delta',
                {'text': 'stale tail'},
                sessionId: 'live-session',
                seq: 801,
              );
            }
          },
        );
        final turn = await _replayRepository(socket).openLiveTurn(
          storedSessionId: 'stored-session',
          recover: true,
          after: const GatewayReplayCursor(
            sessionId: 'live-session',
            epoch: 'process-2',
            seq: 1,
          ),
        );
        final events = <RunEvent>[];
        final subscription = turn.events.listen(events.add);
        await Future<void>.delayed(Duration.zero);
        expect(resumes, 2);
        expect(turn.recoveryMode, GatewayRecoveryMode.snapshot);
        expect(turn.running, false);
        expect(turn.inflight?.assistant, 'retained partial');
        expect(turn.inflight?.status, 'error');
        expect(events.whereType<RunTextDelta>(), isEmpty);
        expect(socket.methods, isNot(contains('prompt.submit')));
        await subscription.cancel();
        await turn.close();
      },
    );
  }
  test(
    'cursor corresponde aos deltas reduzidos ao cancelar listener',
    () async {
      final socket = _FakeGatewaySocket(
        readyPayload: const {'replay_epoch': 'process-1'},
      );
      final turn = await _replayRepository(
        socket,
      ).openLiveTurn(storedSessionId: 'stored-session');
      final events = <RunEvent>[];
      late StreamSubscription<RunEvent> subscription;
      subscription = turn.events.listen((event) {
        events.add(event);
        if (event is RunTextDelta) unawaited(subscription.cancel());
      });
      await Future<void>.delayed(Duration.zero);
      for (var seq = 1; seq <= 20; seq++) {
        socket.emit(
          'message.delta',
          {'text': '$seq'},
          sessionId: 'live-session',
          seq: seq,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(events.whereType<RunTextDelta>().length, 1);
      expect(turn.cursor?.seq, 1);
      await turn.close();
    },
  );
  test(
    'cold replay escolhe apenas o último turno e entrega seu terminal',
    () async {
      final socket = _FakeGatewaySocket(
        readyPayload: const {'replay_epoch': 'process-1'},
        resultFor: (method) => method == 'session.resume'
            ? {
                'session_id': 'live-session',
                'running': false,
                'messages': [
                  {'role': 'user', 'text': 'prompt'},
                ],
              }
            : null,
        replayResult: const {
          'epoch': 'process-1',
          'latest_seq': 8,
          'truncated': false,
          'events': [
            {'session_id': 'live-session', 'seq': 1, 'type': 'message.start'},
            {
              'session_id': 'live-session',
              'seq': 2,
              'type': 'message.complete',
              'payload': {'text': 'old'},
            },
            {'session_id': 'live-session', 'seq': 6, 'type': 'message.start'},
            {
              'session_id': 'live-session',
              'seq': 7,
              'type': 'message.delta',
              'payload': {'text': 'new'},
            },
            {
              'session_id': 'live-session',
              'seq': 8,
              'type': 'message.complete',
              'payload': {'text': 'new', 'status': 'complete'},
            },
          ],
        },
      );
      final turn = await _replayRepository(
        socket,
      ).openLiveTurn(storedSessionId: 'stored-session', recover: true);
      final events = <RunEvent>[];
      final subscription = turn.events.listen(events.add);
      await Future<void>.delayed(Duration.zero);
      expect(turn.recoveryMode, GatewayRecoveryMode.turn);
      expect(events.whereType<RunTextDelta>().map((e) => e.text), ['new']);
      expect(events.whereType<RunCompleted>().single.output, 'new');
      expect(turn.cursor?.seq, 8);
      await subscription.cancel();
      await turn.close();
    },
  );
  test('replay preenche a lacuna antes do live e deduplica por seq', () async {
    final socket = _FakeGatewaySocket(
      readyPayload: const {'replay_epoch': 'process-1'},
      replayResult: const {
        'epoch': 'process-1',
        'truncated': false,
        'latest_seq': 12,
        'events': [
          {
            'type': 'message.delta',
            'session_id': 'live-session',
            'seq': 11,
            'payload': {'text': 'gap'},
          },
          {
            'type': 'tool.complete',
            'session_id': 'live-session',
            'seq': 12,
            'payload': {
              'name': 'terminal',
              'tool_id': 't1',
              'result': {'output': 'ok'},
            },
          },
        ],
        'open_requests': [],
      },
      onCall: (method, socket) {
        if (method != 'session.events.since') return;
        socket.emit(
          'message.delta',
          {'text': 'new'},
          sessionId: 'live-session',
          seq: 13,
        );
        socket.emit(
          'message.delta',
          {'text': 'gap'},
          sessionId: 'live-session',
          seq: 11,
        );
        socket.emit(
          'message.delta',
          {'text': 'foreign'},
          sessionId: 'other-session',
          seq: 99,
        );
      },
    );
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
      recover: true,
      after: const GatewayReplayCursor(
        sessionId: 'live-session',
        epoch: 'process-1',
        seq: 10,
      ),
    );
    final events = <RunEvent>[];
    final subscription = turn.events.listen(events.add);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(turn.recoveryMode, GatewayRecoveryMode.gap);
    expect(events.whereType<RunTextDelta>().map((e) => e.text), ['gap', 'new']);
    expect(events.whereType<RunToolProgress>().single.tool.id, 't1');
    expect(turn.cursor?.seq, 13);
    expect(socket.paramsFor('session.events.since')['last_seen'], 10);
    expect(socket.methods, isNot(contains('prompt.submit')));
    await subscription.cancel();
    await turn.close();
  });
  test(
    'resume aceita transcript projetado com text, row_id e tools compactas',
    () async {
      final socket = _FakeGatewaySocket(
        resumeMessages: const [
          {'role': 'user', 'text': 'Verifique', 'row_id': 41},
          {
            'role': 'tool',
            'name': 'terminal',
            'tool_call_id': 'tool-1',
            'context': 'sleep 2',
            'args': {'command': 'sleep 2'},
          },
          {
            'role': 'assistant',
            'text': 'Pronto',
            'row_id': 43,
            'display_kind': 'reply',
          },
        ],
      );
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      final timeline = conversationTimeline(turn.initialHistory);
      expect((timeline.first as UserMessage).text, 'Verifique');
      final reply = timeline.last as AssistantMessage;
      expect(reply.text, 'Pronto');
      expect(reply.id, 'gateway-row-43');
      expect(turn.initialHistory.last.rowId, 43);
      expect(reply.tools.single.id, 'tool-1');
      expect(reply.tools.single.detail, 'sleep 2');
      expect(reply.tools.single.arg, 'sleep 2');
      await turn.close();
    },
  );
  test('catálogo de skills lê a lista solta do Dashboard', () async {
    final adapter = _DashboardAdapter();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = adapter,
    );

    final skills = await repository.skills();

    expect(adapter.requests.single.uri.path, '/api/skills');
    expect(adapter.requests.single.headers['Cookie'], 'session=opaque');
    expect(skills, const [
      HermesSkill(
        name: 'deploy',
        description: 'Publica a build',
        category: 'ops',
        enabled: false,
      ),
    ]);
  });

  group('gestão de skills', () {
    late _DashboardAdapter adapter;
    late DashboardGatewayRepository repository;

    setUp(() {
      adapter = _DashboardAdapter();
      repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = adapter,
      );
    });

    test('lê o SKILL.md com o nome codificado na query', () async {
      final content = await repository.skillContent('ops/deploy');

      expect(content, '---\nname: deploy\n---\nCorpo\n');
      expect(adapter.requests.single.uri.queryParameters, {
        'name': 'ops/deploy',
      });
    });

    test('grava o SKILL.md e ativa com os corpos do Dashboard', () async {
      await repository.saveSkillContent('deploy', '---\nname: deploy\n---\n');
      await repository.setSkillEnabled('deploy', enabled: false);

      expect(adapter.requests.map((r) => (r.method, r.uri.path)), [
        ('PUT', '/api/skills/content'),
        ('PUT', '/api/skills/toggle'),
      ]);
      expect(adapter.requests.first.data, {
        'name': 'deploy',
        'content': '---\nname: deploy\n---\n',
      });
      expect(adapter.requests.last.data, {'name': 'deploy', 'enabled': false});
    });

    test('recusa de conteúdo chega com a causa do Dashboard', () async {
      await expectLater(
        repository.saveSkillContent('deploy', 'sem frontmatter'),
        throwsA(
          isA<GatewayOperationException>().having(
            (e) => e.message,
            'message',
            'SKILL.md must start with YAML frontmatter (---).',
          ),
        ),
      );
    });
  });

  test('login Basic salva sessão e credenciais separadamente', () async {
    final store = _MemoryDashboardSessionStore();
    final adapter = _DashboardAdapter();
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = adapter,
    );

    await repository.authenticate(
      baseUrl: ' https://dashboard.example:8443/ ',
      username: ' operator ',
      password: 'segredo-de-teste',
    );

    final request = adapter.requests.single;
    expect(request.uri.path, '/auth/password-login');
    expect(request.data, {
      'provider': 'basic',
      'username': 'operator',
      'password': 'segredo-de-teste',
    });
    expect(store.session?.baseUrl, 'https://dashboard.example:8443');
    expect(store.session?.cookies, {'session': 'opaque', 'csrf': 'token'});
    expect(store.serialized, isNot(contains('segredo-de-teste')));
    expect(store.serialized, isNot(contains('operator')));
    expect(store.credentials, (
      baseUrl: 'https://dashboard.example:8443',
      username: 'operator',
      password: 'segredo-de-teste',
    ));
  });

  test('login aceita HTTP quando o Dashboard está no Tailnet', () async {
    final store = _MemoryDashboardSessionStore();
    final adapter = _DashboardAdapter();
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = adapter,
    );

    await repository.authenticate(
      baseUrl: ' HTTP://hermes-gateway.example.ts.net:9119/ ',
      username: 'operator',
      password: 'segredo-de-teste',
    );

    expect(adapter.requests.single.uri.scheme, 'http');
    expect(store.session?.baseUrl, 'http://hermes-gateway.example.ts.net:9119');
  });

  test('login rejeita HTTP fora do Tailnet', () async {
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
    );

    await expectLater(
      repository.authenticate(
        baseUrl: 'http://dashboard.example:9119',
        username: 'operator',
        password: 'segredo-de-teste',
      ),
      throwsA(
        isA<GatewayOperationException>().having(
          (error) => error.message,
          'message',
          contains('MagicDNS do Tailnet'),
        ),
      ),
    );
  });

  test('validação de URL não aceita origem ambígua ou escopo amplo', () {
    expect(
      DashboardGatewayRepository.supportsBaseUrl(
        'http://hermes-gateway.example.ts.net:9119',
      ),
      isTrue,
    );
    expect(
      DashboardGatewayRepository.supportsBaseUrl(
        'https://dashboard.example:8443',
      ),
      isTrue,
    );
    expect(
      DashboardGatewayRepository.supportsBaseUrl('http://ts.net:9119'),
      isFalse,
    );
    expect(
      DashboardGatewayRepository.supportsBaseUrl('http://100.64.0.1:9119'),
      isFalse,
    );
    expect(
      DashboardGatewayRepository.supportsBaseUrl(
        'http://hermes-gateway.example.ts.net:9119/api',
      ),
      isFalse,
    );
    expect(
      DashboardGatewayRepository.supportsBaseUrl(
        'http://user@hermes-gateway.example.ts.net:9119',
      ),
      isFalse,
    );
  });

  test('login recusado não persiste sessão', () async {
    final store = _MemoryDashboardSessionStore();
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = _DashboardAdapter(loginStatusCode: 401),
    );

    await expectLater(
      repository.authenticate(
        baseUrl: 'https://dashboard.example:8443',
        username: 'alguem',
        password: 'incorreta',
      ),
      throwsA(
        isA<GatewayOperationException>().having(
          (error) => error.message,
          'message',
          'Usuário ou senha do Dashboard inválidos.',
        ),
      ),
    );
    expect(store.session, isNull);
  });

  test('transcrição usa cookie da sessão e devolve somente a fala', () async {
    final store = _MemoryDashboardSessionStore(
      session: (
        baseUrl: 'https://dashboard.example:8443',
        cookies: {'session': 'opaque'},
      ),
    );
    final adapter = _DashboardAdapter();
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = adapter,
    );
    final audio = ComposerAttachment(
      id: 'voice-1',
      name: 'voz.m4a',
      mimeType: 'audio/mp4',
      bytes: Uint8List.fromList([1, 2, 3]),
      kind: ComposerAttachmentKind.audio,
    );

    expect(await repository.transcribeAudio(audio), 'texto transcrito');

    final request = adapter.requests.single;
    expect(request.uri.path, '/api/audio/transcribe');
    expect(request.headers['Cookie'], 'session=opaque');
    expect(request.data, {
      'data_url': 'data:audio/mp4;base64,AQID',
      'mime_type': 'audio/mp4',
    });
  });

  test(
    'credenciais salvas recriam sessão ausente sem abrir novo login',
    () async {
      final store = _MemoryDashboardSessionStore(
        credentials: (
          baseUrl: 'https://dashboard.example:8443',
          username: 'operator',
          password: 'segredo-de-teste',
        ),
      );
      final adapter = _DashboardAdapter();
      final repository = DashboardGatewayRepository(
        store: store,
        dio: Dio()..httpClientAdapter = adapter,
      );
      final audio = ComposerAttachment(
        id: 'voice-1',
        name: 'voz.m4a',
        mimeType: 'audio/mp4',
        bytes: Uint8List.fromList([1, 2, 3]),
        kind: ComposerAttachmentKind.audio,
      );

      expect(await repository.transcribeAudio(audio), 'texto transcrito');
      expect(adapter.requests.map((request) => request.uri.path), [
        '/auth/password-login',
        '/api/audio/transcribe',
      ]);
      expect(store.session?.cookies, {'session': 'opaque', 'csrf': 'token'});
    },
  );

  test('401 autenticado apaga cookie e exige novo login', () async {
    final store = _MemoryDashboardSessionStore(
      session: (
        baseUrl: 'https://dashboard.example:8443',
        cookies: {'session': 'expirada'},
      ),
    );
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()
        ..httpClientAdapter = _DashboardAdapter(transcribeStatusCode: 401),
    );
    final audio = ComposerAttachment(
      id: 'voice-1',
      name: 'voz.m4a',
      mimeType: 'audio/mp4',
      bytes: Uint8List(0),
      kind: ComposerAttachmentKind.audio,
    );

    await expectLater(
      repository.transcribeAudio(audio),
      throwsA(isA<GatewayAuthenticationRequired>()),
    );
    expect(store.session, isNull);
    expect(store.cleared, isTrue);
  });

  test(
    '401 renova a sessão com credenciais salvas e repete a operação',
    () async {
      final store = _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'expirada'},
        ),
        credentials: (
          baseUrl: 'https://dashboard.example:8443',
          username: 'operator',
          password: 'segredo-de-teste',
        ),
      );
      final adapter = _DashboardAdapter(expireFirstTranscription: true);
      final repository = DashboardGatewayRepository(
        store: store,
        dio: Dio()..httpClientAdapter = adapter,
      );
      final audio = ComposerAttachment(
        id: 'voice-1',
        name: 'voz.m4a',
        mimeType: 'audio/mp4',
        bytes: Uint8List.fromList([1, 2, 3]),
        kind: ComposerAttachmentKind.audio,
      );

      expect(await repository.transcribeAudio(audio), 'texto transcrito');

      expect(adapter.requests.map((request) => request.uri.path), [
        '/api/audio/transcribe',
        '/auth/password-login',
        '/api/audio/transcribe',
      ]);
      expect(adapter.requests.first.headers['Cookie'], 'session=expirada');
      expect(
        adapter.requests.last.headers['Cookie'],
        'session=opaque; csrf=token',
      );
      expect(store.session?.cookies, {'session': 'opaque', 'csrf': 'token'});
      expect(store.credentialsCleared, isFalse);
    },
  );

  test('credenciais salvas recusadas são apagadas após o 401', () async {
    final store = _MemoryDashboardSessionStore(
      session: (
        baseUrl: 'https://dashboard.example:8443',
        cookies: {'session': 'expirada'},
      ),
      credentials: (
        baseUrl: 'https://dashboard.example:8443',
        username: 'operator',
        password: 'antiga',
      ),
    );
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()
        ..httpClientAdapter = _DashboardAdapter(
          loginStatusCode: 401,
          transcribeStatusCode: 401,
        ),
    );
    final audio = ComposerAttachment(
      id: 'voice-1',
      name: 'voz.m4a',
      mimeType: 'audio/mp4',
      bytes: Uint8List(0),
      kind: ComposerAttachmentKind.audio,
    );

    await expectLater(
      repository.transcribeAudio(audio),
      throwsA(isA<GatewayAuthenticationRequired>()),
    );

    expect(store.session, isNull);
    expect(store.credentials, isNull);
    expect(store.credentialsCleared, isTrue);
  });

  test('live turn usa id live e traduz a timeline tipada', () async {
    final store = _MemoryDashboardSessionStore(
      session: (
        baseUrl: 'https://dashboard.example:8443',
        cookies: {'session': 'opaque'},
      ),
    );
    final adapter = _DashboardAdapter();
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = adapter,
      socketConnector: (uri, {required headers}) async {
        expect(uri.scheme, 'wss');
        expect(uri.path, '/api/ws');
        expect(uri.queryParameters['ticket'], 'ticket-efemero');
        expect(headers['Origin'], 'https://dashboard.example:8443');
        return socket;
      },
    );

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    expect(turn.liveSessionId, 'live-session');
    expect(turn.running, isTrue);
    expect(turn.initialHistory.single.content, 'Pergunta anterior');

    await turn.submit('Nova pergunta');
    await turn.respondToApproval(ApprovalChoice.once);
    await turn.interrupt();

    expect(socket.paramsFor('prompt.submit'), {
      'session_id': 'live-session',
      'text': 'Nova pergunta',
    });
    expect(socket.paramsFor('approval.respond')['session_id'], 'live-session');

    final eventsFuture = turn.events.take(7).toList();
    socket
      ..emit('reasoning.delta', {'text': 'Plano'})
      ..emit('message.delta', {'text': ' com espaço'})
      ..emit('thinking.delta', {'text': 'Pensando'})
      ..emit('tool.start', {
        'tool_id': 'tool-1',
        'name': 'terminal',
        'args_text': 'flutter test',
      })
      ..emit('tool.complete', {
        'tool_id': 'tool-1',
        'name': 'terminal',
        'summary': 'ok',
        'duration_s': 1.2,
      })
      ..emitServerRequest('clarify-batch', 'clarify', {
        'session_id': 'live-session',
        'questions': [
          {
            'qid': 'q0',
            'question': 'Qual formato?',
            'choices': ['Curto'],
          },
          {'qid': '', 'question': 'Entrada inválida'},
          {'qid': 'q1', 'question': 'Qual detalhe?'},
        ],
        'answers': {'q0': 'Curto'},
      })
      ..emit('message.complete', {'text': 'Resposta', 'status': 'complete'});
    final events = await eventsFuture;

    expect(events[0], isA<RunReasoningDelta>());
    expect((events[1] as RunTextDelta).text, ' com espaço');
    // Estado transitório, não prévia de atividade: ver A59.
    expect((events[2] as RunThinkingState).text, 'Pensando');
    expect((events[3] as RunToolProgress).tool.status, ToolStatus.running);
    expect((events[4] as RunToolProgress).tool.status, ToolStatus.done);
    final clarify = (events[5] as RunClarifyRequest).request;
    expect(clarify.requestId, 'clarify-batch');
    expect(clarify.questions.map((question) => question.id), ['q0', 'q1']);
    expect(clarify.answers, {'q0': 'Curto'});
    expect((events[6] as RunCompleted).output, 'Resposta');
    await turn.close();
  });

  test(
    'handshake anuncia server requests e responde clarify com o mesmo id',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );

      final eventFuture = turn.events.first;
      socket.emitServerRequest('srq-clarify', 'clarify', {
        'session_id': 'live-session',
        'questions': [
          {
            'qid': 'q0',
            'question': 'Continuar?',
            'choices': ['Sim', 'Não'],
          },
        ],
      });
      final request = ((await eventFuture) as RunClarifyRequest).request;

      expect(request.requestId, 'srq-clarify');
      expect(
        socket.requests.any(
          (request) => request['method'] == 'client.capabilities',
        ),
        isTrue,
      );
      await turn.close();
    },
  );

  test(
    'aprovação server request responde escolha pelo id do envelope',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      final eventFuture = turn.events.first;
      socket.emitServerRequest('srq-approval', 'approval', {
        'session_id': 'live-session',
        'request_id': 'approval-1',
        'command': 'echo safe',
        'description': 'Teste',
        'choices': ['once', 'deny'],
      });
      final request = ((await eventFuture) as RunApprovalRequest).request;

      expect(request.requestId, 'srq-approval');
      await turn.respondToApproval(
        ApprovalChoice.once,
        requestId: request.requestId,
      );
      expect(socket.responses.single['id'], 'srq-approval');
      expect(socket.responses.single['result'], {
        'choice': 'once',
        'all': false,
      });
      await turn.close();
    },
  );

  test(
    'prompts sensíveis e métodos desconhecidos são rejeitados sem UI',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );

      socket.emitServerRequest('srq-secret', 'secret', {
        'session_id': 'live-session',
        'env_var': 'API_KEY',
        'prompt': 'não deve aparecer',
      });
      socket.emitServerRequest('srq-unknown', 'vault.unlock_prompt', {
        'session_id': 'live-session',
        'display_name': 'Vault',
      });
      await Future<void>.delayed(Duration.zero);

      expect(socket.responses, hasLength(2));
      expect(socket.responses.map((response) => response['id']), [
        'srq-secret',
        'srq-unknown',
      ]);
      expect(
        socket.responses.every(
          (response) => (response['error'] as Map)['code'] == -32601,
        ),
        isTrue,
      );
      await turn.close();
    },
  );

  test(
    'pedido de janela do Desktop recebe 4404 para não vencer a janela dona',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      for (final method in [
        'preview.act',
        'preview.read',
        'terminal.read',
        'theme.apply',
        'theme.pick',
        'setup_beat',
        'window.read',
        'tour',
      ]) {
        socket.emitServerRequest('srq-$method', method, {
          'session_id': 'live-session',
          'action': 'click',
        });
      }
      await Future<void>.delayed(Duration.zero);

      expect(socket.responses, hasLength(8));
      expect(
        socket.responses.map((response) => (response['error'] as Map)['code']),
        everyElement(4404),
      );
      await turn.close();
    },
  );

  test(
    'server request com shape incompatível recebe erro sem criar prompt',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );

      socket.emitServerRequest('srq-invalid', 'clarify', {'questions': []});
      await Future<void>.delayed(Duration.zero);

      expect(socket.responses.single['id'], 'srq-invalid');
      expect((socket.responses.single['error'] as Map)['code'], -32602);
      await turn.close();
    },
  );

  test('server request de outra sessão é rejeitado sem criar prompt', () async {
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    socket.emitServerRequest('srq-foreign', 'clarify', {
      'session_id': 'other-live-session',
      'questions': [
        {'qid': 'q0', 'question': 'Não mostrar'},
      ],
    });
    await Future<void>.delayed(Duration.zero);

    expect(socket.responses.single['id'], 'srq-foreign');
    expect((socket.responses.single['error'] as Map)['code'], -32602);
    await turn.close();
  });

  test(
    'batch server request usa clarify.lock por qid e JSON para multiselect',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      final eventFuture = turn.events.first;
      socket.emitServerRequest('srq-batch', 'clarify', {
        'session_id': 'live-session',
        'questions': [
          {
            'qid': 'q0',
            'question': 'Quais?',
            'choices': ['Web', 'Mobile'],
            'multi_select': true,
          },
          {'qid': 'q1', 'question': 'Nome?'},
        ],
      });
      final request = ((await eventFuture) as RunClarifyRequest).request;

      final first = await turn.lockClarification(
        requestId: request.requestId,
        questionId: 'q0',
        answer: ['Web', 'Mobile'],
      );
      expect(first.remaining, ['q1']);
      final last = await turn.lockClarification(
        requestId: request.requestId,
        questionId: 'q1',
        answer: 'Equipe',
      );
      expect(last.remaining, isEmpty);
      expect(socket.paramsFor('clarify.lock'), {
        'request_id': 'srq-batch',
        'question_id': 'q1',
        'answer': 'Equipe',
      });
      expect(
        socket.requests
            .where((request) => request['method'] == 'clarify.lock')
            .first['params']['answer'],
        '["Web","Mobile"]',
      );
      expect(socket.responses, isEmpty);
      await turn.close();
    },
  );

  test('replay de outra sessão é rejeitado pelo ownership', () async {
    final socket = _FakeGatewaySocket(
      openRequests: [
        {
          'id': 'srq-foreign-replay',
          'method': 'clarify',
          'params': {
            'session_id': 'other-live-session',
            'questions': [
              {'qid': 'q0', 'question': 'Não mostrar'},
            ],
          },
        },
      ],
    );
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await Future<void>.delayed(Duration.zero);
    expect(socket.responses.single['id'], 'srq-foreign-replay');
    expect((socket.responses.single['error'] as Map)['code'], -32602);
    await turn.close();
  });

  test('aprovação por server request falha alto com o canal fechado', () async {
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.close();

    await expectLater(
      turn.respondToApproval(ApprovalChoice.once, requestId: 'srq-approval'),
      throwsA(isA<GatewayOperationException>()),
    );
    expect(socket.responses, isEmpty);
  });

  test(
    'pedido sem sessão vinculada recebe erro quando o resume falha',
    () async {
      final socket = _FakeGatewaySocket(
        failures: {'session.resume': (code: -32000, message: 'boom')},
        failureDelay: const Duration(milliseconds: 40),
      );
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final aberto = repository.openLiveTurn(storedSessionId: 'stored-session');
      final falha = expectLater(
        aberto,
        throwsA(isA<GatewayOperationException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      socket.emitServerRequest('srq-orphan', 'clarify', {
        'session_id': 'live-session',
        'questions': [
          {'qid': 'q0', 'question': 'Sem dono?'},
        ],
      });
      await falha;

      expect(socket.responses.single['id'], 'srq-orphan');
      expect((socket.responses.single['error'] as Map)['code'], -32603);
    },
  );

  test('stream fecha sem listener e não trava com ready buffered', () async {
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.close().timeout(const Duration(milliseconds: 300));
    expect(socket.closed, isTrue);
  });

  test('stream de lifecycle não emite ready nos eventos do turno', () async {
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    final eventFuture = turn.events.first;
    socket.emit('message.delta', {'text': 'turno'});
    expect((await eventFuture), isA<RunTextDelta>());
    await turn.close();
  });

  test('stream fecha após cancelar listener com replay pendente', () async {
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    final subscription = turn.events.listen((_) {});
    await subscription.cancel();
    socket.emitServerRequest('srq-after-cancel', 'clarify', {
      'session_id': 'live-session',
      'questions': [
        {'qid': 'q0', 'question': 'Replay'},
      ],
    });
    await Future<void>.delayed(Duration.zero);
    await turn.close().timeout(const Duration(milliseconds: 300));
    expect(socket.closed, isTrue);
  });

  test('open_requests de session.resume é entregue após reconectar', () async {
    final socket = _FakeGatewaySocket(
      openRequests: [
        {
          'id': 'srq-replayed',
          'method': 'clarify',
          'params': {
            'session_id': 'live-session',
            'questions': [
              {'qid': 'q0', 'question': 'Já travada?'},
              {'qid': 'q1', 'question': 'Retomar?'},
            ],
            'answers': {'q0': null},
          },
        },
      ],
    );
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    final event = await turn.events.first;
    final request = (event as RunClarifyRequest).request;
    expect(request.requestId, 'srq-replayed');
    expect(request.isAnswered('q0'), isTrue);
    expect(request.isAnswered('q1'), isFalse);
    await turn.close();
  });

  test(
    'request.cancel chega como evento tipado sem cancelar outro id',
    () async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      final eventsFuture = turn.events.take(2).toList();
      socket
        ..emitServerRequest('srq-live', 'clarify', {
          'session_id': 'live-session',
          'questions': [
            {'qid': 'q0', 'question': 'Cancelar?'},
          ],
        })
        ..emit('request.cancel', {
          'id': 'srq-other',
          'method': 'clarify',
          'reason': 'timeout',
        });
      final events = await eventsFuture;

      expect(events.first, isA<RunClarifyRequest>());
      expect((events.last as RunUnknown).type, 'request.cancel');
      expect((events.last as RunUnknown).data['id'], 'srq-other');
      await turn.close();
    },
  );

  test('backend antigo sem heartbeat não recebe gateway.ping', () async {
    final socket = _FakeGatewaySocket(readyPayload: const {});
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      heartbeatInterval: const Duration(milliseconds: 2),
      heartbeatDeadline: const Duration(milliseconds: 8),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await Future<void>.delayed(const Duration(milliseconds: 12));
    expect(socket.methods, isNot(contains('gateway.ping')));
    await turn.close();
  });
  test(
    'heartbeat envia gateway.ping somente quando anunciado no ready',
    () async {
      final socket = _FakeGatewaySocket(readyPayload: {'heartbeat': true});
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        heartbeatInterval: const Duration(milliseconds: 2),
        heartbeatDeadline: const Duration(milliseconds: 20),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      await Future<void>.delayed(const Duration(milliseconds: 8));
      expect(socket.methods, contains('gateway.ping'));
      expect(socket.closed, isFalse);
      await turn.close();
    },
  );

  test('heartbeat encerra socket sem frame de entrada no deadline', () async {
    final socket = _FakeGatewaySocket(
      readyPayload: {'heartbeat': true},
      respondToHeartbeat: false,
    );
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      heartbeatInterval: const Duration(milliseconds: 2),
      heartbeatDeadline: const Duration(milliseconds: 8),
      socketConnector: (uri, {required headers}) async => socket,
    );
    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    final events = turn.events.listen((_) {}, onError: (_) {});
    await Future<void>.delayed(const Duration(milliseconds: 18));
    expect(socket.methods, contains('gateway.ping'));
    expect(socket.closed, isTrue);
    await events.cancel();
    await turn.close();
  });
  test(
    'live turn prefere as mensagens devolvidas pelo session.resume',
    () async {
      final socket = _FakeGatewaySocket(
        resumeMessages: const [
          {'id': 'u1', 'role': 'user', 'content': 'Pergunta antiga'},
          {'id': 'a1', 'role': 'assistant', 'content': 'Resposta antiga'},
          {'id': 'u2', 'role': 'user', 'content': 'Pergunta atual'},
        ],
      );
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );

      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );

      expect(turn.initialHistory, hasLength(3));
      expect(turn.initialHistory.first.content, 'Pergunta antiga');
      expect(
        socket.methods,
        ['session.resume'],
        reason: 'não substitui o snapshot do resume por outro mais pobre',
      );
      await turn.close();
    },
  );

  test('histórico concluído vem por HTTP, sem abrir socket', () async {
    final socket = _FakeGatewaySocket();
    final adapter = _DashboardAdapter();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = adapter,
      socketConnector: (uri, {required headers}) async => socket,
    );

    final history = await repository.conversationHistory(
      storedSessionId: 'stored-session',
    );

    expect(history.map((m) => m.content), ['Pergunta anterior', 'Resposta']);
    expect(history.first.rowId, 7);
    expect(
      adapter.requests.single.uri.path,
      '/api/sessions/stored-session/messages',
    );
    expect(adapter.requests.single.uri.queryParameters, {
      'inline_images': 'false',
    });
    expect(socket.methods, isEmpty);
  });

  test('diagnóstico aponta session authority no gateway.ready', () async {
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async =>
          _FakeGatewaySocket(readyPayload: const {'session_authority': true}),
    );

    final steps = await repository.probeGateway();

    expect(steps.first.method, 'gateway.ready');
    expect(steps.first.detail, contains('session authority'));
  });

  test('página cheia do histórico cede ao snapshot do API Server', () async {
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
    );

    await expectLater(
      repository.conversationHistory(storedSessionId: 'long-session'),
      throwsA(isA<GatewayOperationException>()),
    );
  });

  test('live turn usa WS quando o Dashboard está em HTTP', () async {
    final store = _MemoryDashboardSessionStore(
      session: (
        baseUrl: 'http://hermes-gateway.example.ts.net:9119',
        cookies: {'session': 'opaque'},
      ),
    );
    final socket = _FakeGatewaySocket();
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async {
        expect(uri.scheme, 'ws');
        expect(headers['Origin'], 'http://hermes-gateway.example.ts.net:9119');
        return socket;
      },
    );

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.close();
  });

  test('anexo e envio usam uma conexão e uma retomada só', () async {
    final sockets = <_FakeGatewaySocket>[];
    final adapter = _DashboardAdapter();
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = adapter,
      socketConnector: (uri, {required headers}) async {
        final socket = _FakeGatewaySocket();
        sockets.add(socket);
        return socket;
      },
    );

    final prepared = await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(),
    );
    expect(prepared.status, ComposerAttachmentStatus.uploaded);
    expect(prepared.refText, '@file:.hermes/desktop-attachments/nota.txt');

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.submit('Leia o anexo');

    expect(sockets, hasLength(1));
    expect(sockets.single.methods, [
      'session.resume',
      'file.attach',
      'session.history',
      'prompt.submit',
    ]);
    // A retomada do anexo é a mesma do turno: `eager_build` impede que o build
    // disparado pelo attach fique sem transporte ao fechar o socket.
    expect(sockets.single.paramsFor('session.resume'), {
      'session_id': 'stored-session',
      'source': 'mobile',
      'close_on_disconnect': false,
      'eager_build': true,
      'omit_messages': true,
    });
    expect(
      adapter.requests
          .where((request) => request.uri.path == '/api/auth/ws-ticket')
          .length,
      1,
    );

    await turn.close();
  });

  test('vários anexos compartilham a mesma conexão preparada', () async {
    final sockets = <_FakeGatewaySocket>[];
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async {
        final socket = _FakeGatewaySocket();
        sockets.add(socket);
        return socket;
      },
    );

    await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(id: 'file-1'),
    );
    await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(id: 'file-2'),
    );

    expect(sockets, hasLength(1));
    expect(sockets.single.methods, [
      'session.resume',
      'file.attach',
      'file.attach',
    ]);

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.close();
  });

  test('conexão preparada de outra conversa não é reaproveitada', () async {
    final sockets = <_FakeGatewaySocket>[];
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async {
        final socket = _FakeGatewaySocket();
        sockets.add(socket);
        return socket;
      },
    );

    await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(),
    );
    final turn = await repository.openLiveTurn(storedSessionId: 'outra-sessao');

    expect(sockets, hasLength(2));
    expect(sockets.first.closed, isTrue);
    expect(sockets.last.methods.first, 'session.resume');
    await turn.close();
  });

  test('erro do gateway vira mensagem legível e guarda o cru', () async {
    final sockets = <_FakeGatewaySocket>[];
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async {
        final socket = _FakeGatewaySocket(
          failures: {
            'file.attach': (
              code: -32000,
              message:
                  "handler error: 'NoneType' object has no attribute 'execute'",
            ),
          },
        );
        sockets.add(socket);
        return socket;
      },
    );

    await expectLater(
      repository.attachFile(
        storedSessionId: 'stored-session',
        attachment: _fileAttachment(),
      ),
      throwsA(
        isA<GatewayOperationException>()
            .having(
              (error) => error.message,
              'message',
              'O Hermes não conseguiu preparar o anexo. Tente de novo.',
            )
            .having((error) => error.method, 'method', 'file.attach')
            .having((error) => error.code, 'code', -32000)
            .having((error) => error.detail, 'detail', contains('NoneType')),
      ),
    );
    // A falha transitória custa exatamente uma segunda tentativa, e nenhum
    // socket fica aberto depois dela.
    expect(sockets, hasLength(2));
    expect(sockets.every((socket) => socket.closed), isTrue);
  });

  test('anexo repete uma vez em conexão nova após falha transitória', () async {
    final sockets = <_FakeGatewaySocket>[];
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async {
        final socket = _FakeGatewaySocket(
          failures: sockets.isEmpty
              ? {'file.attach': (code: -32000, message: 'handler error: boom')}
              : const {},
        );
        sockets.add(socket);
        return socket;
      },
    );

    final prepared = await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(),
    );

    expect(prepared.refText, '@file:.hermes/desktop-attachments/nota.txt');
    expect(sockets, hasLength(2));
    expect(sockets.first.closed, isTrue);
    expect(sockets.last.closed, isFalse);

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.close();
  });

  test('conexão preparada que morreu é trocada sem perder o anexo', () async {
    final sockets = <_FakeGatewaySocket>[];
    final repository = DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async {
        final socket = _FakeGatewaySocket();
        sockets.add(socket);
        return socket;
      },
    );

    await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(id: 'file-1'),
    );
    // O gateway derruba o canal enquanto a pessoa termina de escrever.
    await sockets.single.close();
    await Future<void>.delayed(Duration.zero);

    final prepared = await repository.attachFile(
      storedSessionId: 'stored-session',
      attachment: _fileAttachment(id: 'file-2'),
    );

    expect(prepared.refText, '@file:.hermes/desktop-attachments/nota.txt');
    expect(sockets, hasLength(2));

    final turn = await repository.openLiveTurn(
      storedSessionId: 'stored-session',
    );
    await turn.close();
  });

  test('handshake rejeita primeiro frame diferente de gateway.ready', () async {
    final store = _MemoryDashboardSessionStore(
      session: (
        baseUrl: 'https://dashboard.example:8443',
        cookies: {'session': 'opaque'},
      ),
    );
    final socket = _FakeGatewaySocket(firstEvent: 'message.delta');
    final repository = DashboardGatewayRepository(
      store: store,
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );

    await expectLater(
      repository.openLiveTurn(storedSessionId: 'stored-session'),
      throwsA(
        isA<GatewayOperationException>().having(
          (error) => error.message,
          'message',
          contains('gateway.ready'),
        ),
      ),
    );
    expect(socket.closed, isTrue);
  });

  // A59. Os payloads abaixo são os shapes medidos num turno real do gateway
  // `0.20.1` em 2026-08-15, registrados em
  // `docs/dashboard-api/tui-eventos-0.20.1-medido.md`. Não são fixture
  // inventada: é o que o `_on_tool_start`/`_on_tool_complete` emite.
  group('A59 · o adapter não pode jogar fora o que o TUI manda', () {
    Future<List<RunEvent>> capturar(
      int quantos,
      void Function(_FakeGatewaySocket socket) emitir,
    ) async {
      final socket = _FakeGatewaySocket();
      final repository = DashboardGatewayRepository(
        store: _MemoryDashboardSessionStore(
          session: (
            baseUrl: 'https://dashboard.example:8443',
            cookies: {'session': 'opaque'},
          ),
        ),
        dio: Dio()..httpClientAdapter = _DashboardAdapter(),
        socketConnector: (uri, {required headers}) async => socket,
      );
      final turn = await repository.openLiveTurn(
        storedSessionId: 'stored-session',
      );
      final eventos = turn.events.take(quantos).toList();
      emitir(socket);
      final resultado = await eventos;
      await turn.close();
      return resultado;
    }

    test(
      'message.complete mapeia complete, error/failure_reason e interrupted',
      () async {
        final completo = await capturar(
          1,
          (socket) => socket.emit('message.complete', {
            'status': 'complete',
            'text': 'Resposta final',
          }),
        );
        expect((completo.single as RunCompleted).output, 'Resposta final');

        final erro = await capturar(
          1,
          (socket) => socket.emit('message.complete', {
            'status': 'error',
            'text': 'texto técnico',
            'failure_reason': 'provider_rate_limit',
          }),
        );
        expect((erro.single as RunFailed).error, 'provider_rate_limit');

        final interrompido = await capturar(
          1,
          (socket) => socket.emit('message.complete', {
            'status': 'interrupted',
            'failure_reason': 'user_stop',
          }),
        );
        expect(
          (interrompido.single as RunStatusEvent).status,
          RunStatus.cancelled,
        );
      },
    );
    test(
      'message.complete aceita failed e fecha status desconhecido',
      () async {
        final falhou = await capturar(
          1,
          (socket) => socket.emit('message.complete', {
            'status': 'failed',
            'error': 'boom',
          }),
        );
        expect((falhou.single as RunFailed).error, 'boom');

        final legado = await capturar(
          1,
          (socket) => socket.emit('message.complete', {
            'status': 'completed',
            'text': 'ok',
          }),
        );
        expect((legado.single as RunCompleted).output, 'ok');

        // Status futuro não é sucesso nem pode deixar o turno aberto.
        final futuro = await capturar(
          1,
          (socket) => socket.emit('message.complete', {
            'status': 'paused',
            'text': 'parcial',
          }),
        );
        expect(futuro.single, isA<RunFailed>());
      },
    );
    test(
      'tool.complete entrega o resultado inteiro, não só o summary',
      () async {
        // Medido: o card ao vivo ficava com 22 caracteres onde a conversa
        // reaberta tinha 44.019, porque o adapter lia só o `summary`.
        final eventos = await capturar(
          1,
          (socket) => socket.emit('tool.complete', {
            'tool_id': 'call_A1',
            'name': 'web_search',
            'args': {'query': 'hora certa'},
            'result': {
              'success': true,
              'data': {
                'web': [
                  {'title': 'Relógio', 'content': 'x' * 200},
                ],
              },
            },
            'summary': 'Did 1 search in 3.6s',
            'duration_s': 3.6,
          }),
        );

        final tool = (eventos.single as RunToolProgress).tool;
        expect(tool.id, 'call_A1');
        expect(tool.status, ToolStatus.done);
        expect(tool.output, contains('Relógio'));
        expect(
          tool.output!.length,
          greaterThan(100),
          reason: 'o resultado inteiro, não o resumo de 20 caracteres',
        );
      },
    );

    test('tool.start guarda os args, que chegam no mesmo frame', () async {
      final eventos = await capturar(
        1,
        (socket) => socket.emit('tool.start', {
          'tool_id': 'call_B2',
          'name': 'terminal',
          'context': 'uptime',
          'args': {'command': 'uptime && date', 'workdir': '/home/hermes'},
        }),
      );

      final tool = (eventos.single as RunToolProgress).tool;
      expect(tool.status, ToolStatus.running);
      // A prévia continua sendo a do servidor, que já passou pelo redator dele.
      expect(tool.arg, 'uptime');
      // E o comando real fica disponível para abrir, igual ao histórico.
      expect(tool.detail, 'uptime && date');
    });

    test(
      'argumento de ferramenta que o servidor redige não é reconstruído',
      () async {
        // `browser_type` tem o texto mascarado no caminho ao vivo do servidor. O
        // app não tem esse redator, então não inventa a prévia a partir dos args.
        final eventos = await capturar(
          1,
          (socket) => socket.emit('tool.start', {
            'tool_id': 'call_C3',
            'name': 'browser_type',
            'args': {'text': 'senha-que-nao-pode-vazar'},
          }),
        );

        final tool = (eventos.single as RunToolProgress).tool;
        expect(tool.arg, isEmpty);
        expect(tool.detail, isNull);
      },
    );

    test('ferramenta que falhou não aparece como concluída', () async {
      // `tool.complete` não tem campo `error` no 0.20.1. O sinal está na
      // convenção de resultado do próprio Hermes.
      final eventos = await capturar(
        1,
        (socket) => socket.emit('tool.complete', {
          'tool_id': 'call_D4',
          'name': 'skill_view',
          'args': {'name': 'inexistente'},
          'result': {'success': false, 'error': 'skill not found'},
        }),
      );

      expect((eventos.single as RunToolProgress).tool.status, ToolStatus.error);
    });

    test(
      'thinking.delta é estado, e o texto vazio é o sinal de limpeza',
      () async {
        final eventos = await capturar(2, (socket) {
          socket
            ..emit('thinking.delta', {'text': '(´･_･`) reasoning...'})
            ..emit('thinking.delta', {'text': ''});
        });

        expect(eventos.map((evento) => (evento as RunThinkingState).text), [
          '(´･_･`) reasoning...',
          '',
        ]);
      },
    );

    test('reasoning.available não vira bloco: é a resposta truncada', () async {
      // Só um evento sai daqui: o `reasoning.available` não produz nada, então
      // o próximo a chegar é a conclusão do turno.
      final eventos = await capturar(1, (socket) {
        socket
          ..emit('reasoning.available', {'text': 'A resposta, cortada em 501'})
          ..emit('message.complete', {
            'text': 'A resposta, cortada em 501 e mais um pedaço',
            'status': 'complete',
          });
      });

      expect(
        (eventos.single as RunCompleted).output,
        'A resposta, cortada em 501 e mais um pedaço',
      );
    });

    test('tool.progress saiu da allowlist: o gateway nunca o emite', () async {
      final eventos = await capturar(
        1,
        (socket) => socket.emit('tool.progress', {'name': 'terminal'}),
      );

      expect((eventos.single as RunUnknown).type, 'tool.progress');
    });
  });
}

ComposerAttachment _fileAttachment({String id = 'file-1'}) =>
    ComposerAttachment(
      id: id,
      name: 'nota.txt',
      mimeType: 'text/plain',
      bytes: Uint8List.fromList([1, 2, 3]),
      kind: ComposerAttachmentKind.file,
      localPath: '/storage/emulated/0/Download/nota.txt',
    );

final class _MemoryDashboardSessionStore implements DashboardSessionStore {
  _MemoryDashboardSessionStore({this.session, this.credentials});

  DashboardSession? session;
  DashboardCredentials? credentials;
  bool cleared = false;
  bool credentialsCleared = false;

  String get serialized => jsonEncode(
    session == null
        ? null
        : {'base_url': session!.baseUrl, 'cookies': session!.cookies},
  );

  @override
  Future<void> clear() async {
    cleared = true;
    session = null;
  }

  @override
  Future<void> clearCredentials() async {
    credentialsCleared = true;
    credentials = null;
  }

  @override
  Future<DashboardSession?> read() async => session;

  @override
  Future<DashboardCredentials?> readCredentials() async => credentials;

  @override
  Future<void> save(DashboardSession value) async => session = value;

  @override
  Future<void> saveCredentials(DashboardCredentials value) async =>
      credentials = value;
}

final class _DashboardAdapter implements HttpClientAdapter {
  _DashboardAdapter({
    this.loginStatusCode = 200,
    this.transcribeStatusCode = 200,
    this.expireFirstTranscription = false,
  });

  final int loginStatusCode;
  final int transcribeStatusCode;
  final bool expireFirstTranscription;
  final List<RequestOptions> requests = [];
  var _transcriptionCount = 0;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (options.uri.path == '/auth/password-login') {
      return _json(
        loginStatusCode == 200 ? {'ok': true, 'next': '/'} : {'ok': false},
        loginStatusCode,
        headers: loginStatusCode == 200
            ? {
                'set-cookie': [
                  'session=opaque; Path=/; HttpOnly',
                  'csrf=token; Path=/; Secure',
                ],
              }
            : null,
      );
    }
    if (options.uri.path == '/api/audio/transcribe') {
      _transcriptionCount += 1;
      final statusCode = expireFirstTranscription && _transcriptionCount == 1
          ? 401
          : transcribeStatusCode;
      return _json(
        statusCode == 200
            ? {'ok': true, 'transcript': ' texto transcrito '}
            : {'detail': 'Unauthorized'},
        statusCode,
      );
    }
    if (options.uri.path == '/api/auth/ws-ticket') {
      return _json({'ticket': 'ticket-efemero'}, 200);
    }
    if (options.uri.path == '/api/sessions/stored-session/messages') {
      return _json({
        'session_id': 'stored-session',
        'profile': 'default',
        'messages': [
          {
            'id': 7,
            'role': 'user',
            'content': 'Pergunta anterior',
            'row_id': 7,
          },
          {'id': 8, 'role': 'assistant', 'content': 'Resposta', 'row_id': 8},
        ],
        'pagination': {
          'limit': 500,
          'offset': 0,
          'order': 'latest',
          'returned': 2,
        },
      }, 200);
    }
    if (options.uri.path == '/api/sessions/long-session/messages') {
      return _json({
        'session_id': 'long-session',
        'messages': <Object>[],
        'pagination': {
          'limit': 500,
          'offset': 0,
          'order': 'latest',
          'returned': 500,
        },
      }, 200);
    }
    if (options.uri.path == '/api/skills/content') {
      if (options.method == 'GET') {
        return options.uri.queryParameters['name'] == 'ops/deploy'
            ? _json({
                'name': 'ops/deploy',
                'content': '---\nname: deploy\n---\nCorpo\n',
                'path': '/srv/skills/ops/deploy/SKILL.md',
              }, 200)
            : _json({'detail': "Skill 'x' not found."}, 404);
      }
      final content = (options.data as Map)['content'] as String;
      return content.startsWith('---')
          ? _json({'success': true}, 200)
          : _json({
              'detail': 'SKILL.md must start with YAML frontmatter (---).',
            }, 400);
    }
    if (options.uri.path == '/api/skills/toggle') {
      return _json({'ok': true, ...(options.data as Map)}, 200);
    }
    if (options.uri.path == '/api/skills' && options.method == 'GET') {
      return _json([
        {
          'name': 'deploy',
          'description': 'Publica a build',
          'category': 'ops',
          'enabled': false,
          'usage': 3,
          'provenance': 'agent',
        },
        {'description': 'sem nome'},
      ], 200);
    }
    return _json({'detail': 'Not found'}, 404);
  }

  ResponseBody _json(
    Object body,
    int statusCode, {
    Map<String, List<String>>? headers,
  }) => ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...?headers,
    },
  );
}

DashboardGatewayRepository _replayRepository(_FakeGatewaySocket socket) =>
    DashboardGatewayRepository(
      store: _MemoryDashboardSessionStore(
        session: (
          baseUrl: 'https://dashboard.example:8443',
          cookies: {'session': 'opaque'},
        ),
      ),
      dio: Dio()..httpClientAdapter = _DashboardAdapter(),
      socketConnector: (uri, {required headers}) async => socket,
    );

final class _FakeGatewaySocket implements GatewaySocket {
  _FakeGatewaySocket({
    this.firstEvent = 'gateway.ready',
    this.readyPayload,
    this.failures = const {},
    this.resumeMessages,
    this.openRequests,
    this.respondToHeartbeat = true,
    this.failureDelay,
    this.replayResult,
    this.onCall,
    this.resultFor,
  }) {
    _stream = StreamController<dynamic>(
      onListen: () {
        scheduleMicrotask(() => emit(firstEvent, readyPayload ?? const {}));
      },
    );
  }

  final String firstEvent;
  final Map<String, dynamic>? readyPayload;
  final Map<String, dynamic>? replayResult;
  final void Function(String method, _FakeGatewaySocket socket)? onCall;
  final Map<String, dynamic>? Function(String method)? resultFor;

  /// Métodos que este socket responde com erro JSON-RPC.
  final Map<String, ({int code, String message})> failures;
  final List<Map<String, dynamic>>? resumeMessages;
  final List<Map<String, dynamic>>? openRequests;
  final bool respondToHeartbeat;

  /// Atrasa as respostas de erro, para um server request chegar antes delas.
  final Duration? failureDelay;
  late final StreamController<dynamic> _stream;
  final List<Map<String, dynamic>> requests = [];
  bool closed = false;

  List<String> get methods => requests
      .map((request) => request['method'])
      .whereType<String>()
      .where((method) => method != 'client.capabilities')
      .toList();

  final List<Map<String, dynamic>> responses = [];

  @override
  int? get closeCode => null;

  @override
  Stream<dynamic> get stream => _stream.stream;

  @override
  void add(String data) {
    final request = jsonDecode(data) as Map<String, dynamic>;
    if (request['method'] is! String) {
      responses.add(request);
      return;
    }
    requests.add(request);
    final method = request['method'] as String;
    onCall?.call(method, this);
    if (method == 'gateway.ping' && !respondToHeartbeat) return;
    final failure = failures[method];
    if (failure != null) {
      Future<void>.delayed(failureDelay ?? Duration.zero, () {
        if (_stream.isClosed) return;
        _stream.add(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': request['id'],
            'error': {'code': failure.code, 'message': failure.message},
          }),
        );
      });
      return;
    }
    final result =
        resultFor?.call(method) ??
        switch (method) {
          'session.resume' => {
            'session_id': 'live-session',
            'running': true,
            'status': 'streaming',
            if (resumeMessages != null) 'messages': resumeMessages,
            if (openRequests != null) 'open_requests': openRequests,
          },
          'session.history' => {
            'count': 1,
            'messages': [
              {
                'id': 'message-1',
                'role': 'user',
                'content': 'Pergunta anterior',
              },
            ],
          },
          'session.events.since' => replayResult ?? <String, dynamic>{},
          'file.attach' => {
            'attached': true,
            'name': 'nota.txt',
            'ref_text': '@file:.hermes/desktop-attachments/nota.txt',
          },
          'prompt.submit' => {'status': 'streaming'},
          'session.interrupt' => {'status': 'interrupted'},
          'approval.respond' => {'resolved': true},
          'clarify.lock' => {
            'status': 'ok',
            'remaining': ((request['params'] as Map)['question_id'] == 'q0')
                ? ['q1']
                : const <String>[],
          },
          'client.capabilities' => {
            'server_requests': ['clarify', 'approval'],
            'declines_not_shown': true,
          },
          _ => <String, dynamic>{},
        };
    scheduleMicrotask(() {
      if (_stream.isClosed) return;
      _stream.add(
        jsonEncode({'jsonrpc': '2.0', 'id': request['id'], 'result': result}),
      );
    });
  }

  Map<String, dynamic> paramsFor(String method) =>
      (requests.lastWhere((request) => request['method'] == method)['params']
              as Map)
          .map((key, value) => MapEntry(key.toString(), value));

  void emit(
    String type,
    Map<String, dynamic> payload, {
    String? sessionId,
    int? seq,
  }) {
    if (_stream.isClosed) return;
    _stream.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'method': 'event',
        'params': {
          'type': type,
          'payload': payload,
          'session_id': ?sessionId,
          'seq': ?seq,
        },
      }),
    );
  }

  void emitServerRequest(
    String id,
    String method,
    Map<String, dynamic> params,
  ) {
    if (_stream.isClosed) return;
    _stream.add(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': id,
        'method': method,
        'params': params,
      }),
    );
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!_stream.isClosed) await _stream.close();
  }
}
