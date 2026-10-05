import 'package:flutter_test/flutter_test.dart';
import 'package:hermes_mobile/domain/models/capabilities.dart';
import 'package:hermes_mobile/domain/models/chat_message.dart';
import 'package:hermes_mobile/domain/models/conversation.dart';
import 'package:hermes_mobile/domain/models/health_status.dart';
import 'package:hermes_mobile/domain/models/hermes_model.dart';
import 'package:hermes_mobile/domain/models/run.dart';
import 'package:hermes_mobile/domain/models/session_message.dart';
import 'package:hermes_mobile/domain/models/tool_call.dart';

void main() {
  group('Run', () {
    test('fromJson mapeia run_id, status e usage aninhado', () {
      final run = Run.fromJson({
        'object': 'hermes.run',
        'run_id': 'run_abc123',
        'status': 'completed',
        'session_id': 'sess-1',
        'model': 'hermes-agent',
        'output': 'Done.',
        'usage': {
          'input_tokens': 50,
          'output_tokens': 200,
          'total_tokens': 250,
        },
      });

      expect(run.runId, 'run_abc123');
      expect(run.status, RunStatus.completed);
      expect(run.sessionId, 'sess-1');
      expect(run.usage?.totalTokens, 250);
      expect(run.isTerminal, isTrue);
      expect(run.isActive, isFalse);
    });

    test('status desconhecido cai em RunStatus.unknown (não lança)', () {
      final run = Run.fromJson({'run_id': 'r1', 'status': 'teleporting'});
      expect(run.status, RunStatus.unknown);
    });

    test('isActive cobre os estados em andamento', () {
      expect(const Run(runId: 'r', status: RunStatus.running).isActive, isTrue);
      expect(const Run(runId: 'r', status: RunStatus.started).isActive, isTrue);
      expect(
        const Run(runId: 'r', status: RunStatus.stopping).isActive,
        isFalse,
      );
    });
  });

  group('HealthStatus', () {
    test('online é true só quando status == ok', () {
      expect(HealthStatus.fromJson({'status': 'ok'}).online, isTrue);
      expect(HealthStatus.fromJson({'status': 'degraded'}).online, isFalse);
      expect(const HealthStatus().online, isFalse); // default 'unknown'
    });
  });

  group('Capabilities', () {
    test('fromJson lê as features com nomes snake_case', () {
      final caps = Capabilities.fromJson({
        'platform': 'hermes-agent',
        'model': 'hermes-agent',
        'features': {
          'chat_completions': true,
          'run_stop': true,
          'run_events_sse': true,
          'chat_completions_streaming': true,
          'responses_streaming': true,
          'run_approval_response': true,
          'tool_progress_events': true,
          'approval_events': true,
          'session_chat': true,
          'session_chat_streaming': true,
          'session_fork': true,
          'jobs_admin': true,
          'audio_api': true,
          'realtime_voice': true,
          'cors': true,
          'session_continuity_header': 'x-hermes-session-id',
          'session_key_header': 'x-hermes-session-key',
        },
        'auth': {'type': 'bearer', 'required': true},
      });
      expect(caps.platform, 'hermes-agent');
      expect(caps.features.runStop, isTrue);
      expect(caps.features.runEventsSse, isTrue);
      expect(caps.features.responsesApi, isFalse); // ausente => default false
      expect(caps.features.chatCompletionsStreaming, isTrue);
      expect(caps.features.responsesStreaming, isTrue);
      expect(caps.features.runApprovalResponse, isTrue);
      expect(caps.features.toolProgressEvents, isTrue);
      expect(caps.features.approvalEvents, isTrue);
      expect(caps.features.sessionChat, isTrue);
      expect(caps.features.sessionChatStreaming, isTrue);
      expect(caps.features.sessionFork, isTrue);
      expect(caps.features.jobsAdmin, isTrue);
      expect(caps.features.audioApi, isTrue);
      expect(caps.features.realtimeVoice, isTrue);
      expect(caps.features.cors, isTrue);
      expect(caps.features.sessionContinuityHeader, 'x-hermes-session-id');
      expect(caps.features.sessionKeyHeader, 'x-hermes-session-key');
      expect(caps.auth.type, 'bearer');
      expect(caps.auth.required, isTrue);
    });

    test('features ausente usa o default vazio', () {
      final caps = Capabilities.fromJson({'model': 'x'});
      expect(caps.features.runStop, isFalse);
      expect(caps.auth.type, isNull);
      expect(caps.auth.required, isFalse);
    });
  });

  group('HermesModel', () {
    test('fromJson preserva o modelo anunciado pelo gateway', () {
      final model = HermesModel.fromJson({
        'id': 'hermes-agent',
        'owned_by': 'nous',
      });
      expect(model.id, 'hermes-agent');
      expect(model.ownedBy, 'nous');
    });
  });

  group('ChatMessage (sealed)', () {
    test('pattern matching distingue user e assistant', () {
      const ChatMessage user = ChatMessage.user(
        id: 'u1',
        text: 'oi',
        time: '09:00',
      );
      const ChatMessage asst = ChatMessage.assistant(id: 'a1');

      String describe(ChatMessage m) => switch (m) {
        UserMessage() => 'user',
        AssistantMessage() => 'assistant',
      };

      expect(describe(user), 'user');
      expect(describe(asst), 'assistant');
    });

    test('assistant tem defaults corretos e copyWith', () {
      const msg = ChatMessage.assistant(id: 'a1') as AssistantMessage;
      expect(msg.phase, ChatPhase.reasoning);
      expect(msg.tools, isEmpty);
      expect(msg.text, '');

      final updated = msg.copyWith(
        phase: ChatPhase.done,
        text: 'pronto',
        tools: const [ToolCall(name: 'read_file', arg: 'x.md')],
      );
      expect(updated.phase, ChatPhase.done);
      expect(updated.text, 'pronto');
      expect(updated.tools.single.name, 'read_file');
      // imutabilidade: o original não mudou
      expect(msg.text, '');
    });
  });

  group('Conversation', () {
    test('fromJson preserva os metadados de sessão expostos pelo gateway', () {
      final conversation = Conversation.fromJson({
        'id': 'session-child',
        'title': 'Ramo de teste',
        'source': 'telegram',
        'parent_session_id': 'session-root',
        'last_active': 1784217600.5,
        'started_at': '2026-07-16T00:00:00Z',
        'tool_call_count': 3.5,
        'input_tokens': 120.25,
        'output_tokens': 450.75,
        'estimated_cost_usd': 0.0123,
        'actual_cost_usd': 0.01,
      });

      expect(conversation.source, 'telegram');
      expect(conversation.lastActive, DateTime.fromMillisecondsSinceEpoch(1784217600500, isUtc: true));
      expect(conversation.startedAt, DateTime.utc(2026, 7, 16));
      expect(conversation.parentSessionId, 'session-root');
      expect(conversation.toolCallCount, 3.5);
      expect(conversation.inputTokens, 120.25);
      expect(conversation.outputTokens, 450.75);
      expect(conversation.estimatedCostUsd, closeTo(0.0123, 0.00001));
      expect(conversation.actualCostUsd, closeTo(0.01, 0.00001));
    });
  });

  group('SessionMessage', () {
    test('fromJson preserva campos adicionais e timestamp epoch', () {
      final message = SessionMessage.fromJson({
        'id': 'msg_1',
        'role': 'tool',
        'timestamp': 1784217600123,
        'tool_call_id': 'call_1',
        'tool_calls': [
          {'id': 'call_1', 'function': {'name': 'terminal'}},
        ],
        'token_count': 12.5,
        'finish_reason': 'tool_calls',
      });

      expect(message.timestamp, DateTime.fromMillisecondsSinceEpoch(1784217600123, isUtc: true));
      expect(message.toolCallId, 'call_1');
      expect(message.toolCalls, isA<List<dynamic>>());
      expect(message.tokenCount, 12.5);
      expect(message.finishReason, 'tool_calls');
    });
  });

  group('ToolCall', () {
    test('default status é running', () {
      const t = ToolCall(name: 'terminal');
      expect(t.status, ToolStatus.running);
      expect(t.arg, '');
    });
  });
}
