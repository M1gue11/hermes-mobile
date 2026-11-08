import 'package:freezed_annotation/freezed_annotation.dart';

part 'subagent_run.freezed.dart';

/// Os frames `subagent.*` do TUI Gateway (`tui_gateway/contracts/events.py`).
enum SubagentEventKind {
  spawnRequested('subagent.spawn_requested'),
  start('subagent.start'),
  thinking('subagent.thinking'),
  tool('subagent.tool'),
  progress('subagent.progress'),
  complete('subagent.complete');

  const SubagentEventKind(this.wire);

  final String wire;

  static SubagentEventKind? fromWire(String type) {
    for (final kind in values) {
      if (kind.wire == type) return kind;
    }
    return null;
  }
}

/// Fase legível. O contrato tem sete estados; `failed`, `error` e `timeout`
/// são a mesma coisa para quem lê a timeline.
enum SubagentPhase { queued, running, completed, failed, interrupted }

/// Um frame `subagent.*` já normalizado. Nada daqui vira fala do assistant.
@freezed
abstract class SubagentEvent with _$SubagentEvent {
  const SubagentEvent._();

  const factory SubagentEvent({
    required SubagentEventKind kind,
    required String key,
    @Default('') String goal,
    @Default(0) int taskIndex,
    @Default(1) int taskCount,
    @Default(1) int depth,
    String? text,
    String? toolName,
    String? toolPreview,
    SubagentPhase? phase,
    String? summary,
    Duration? duration,
  }) = _SubagentEvent;

  /// `null` para tipo desconhecido. Todo frame traz `goal`, `task_count` e
  /// `task_index`; `subagent_id` e `delegation_id` são opcionais em emissores
  /// antigos.
  static SubagentEvent? fromGateway(String type, Map<String, dynamic> payload) {
    final kind = SubagentEventKind.fromWire(type);
    if (kind == null) return null;
    String? text(String field) {
      final value = payload[field];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    int number(String field, int fallback) {
      final value = payload[field];
      return value is num ? value.toInt() : fallback;
    }

    final taskIndex = number('task_index', 0);
    final seconds = payload['duration_seconds'];
    return SubagentEvent(
      kind: kind,
      key:
          text('subagent_id') ??
          '${text('delegation_id') ?? 'delegate'}#$taskIndex',
      goal: text('goal') ?? '',
      taskIndex: taskIndex,
      taskCount: number('task_count', 1),
      depth: number('depth', 1),
      text: text('text'),
      toolName: text('tool_name'),
      toolPreview: text('tool_preview'),
      phase: subagentPhaseFromWire(payload['status']),
      summary: text('summary'),
      duration: seconds is num
          ? Duration(milliseconds: (seconds * 1000).round())
          : null,
    );
  }

  bool get opensRun =>
      kind == SubagentEventKind.spawnRequested ||
      kind == SubagentEventKind.start;
}

SubagentPhase? subagentPhaseFromWire(Object? status) => switch (status) {
  'queued' => SubagentPhase.queued,
  'running' => SubagentPhase.running,
  'completed' => SubagentPhase.completed,
  'failed' || 'error' || 'timeout' => SubagentPhase.failed,
  'interrupted' => SubagentPhase.interrupted,
  _ => null,
};

/// Um agente delegado como aparece na timeline do turno pai.
@freezed
abstract class SubagentRun with _$SubagentRun {
  const SubagentRun._();

  const factory SubagentRun({
    required String key,
    @Default('') String goal,
    @Default(0) int taskIndex,
    @Default(1) int taskCount,
    @Default(1) int depth,
    @Default(SubagentPhase.queued) SubagentPhase phase,
    @Default(0) int toolCalls,

    /// Último sinal de vida: ferramenta, progresso ou raciocínio.
    String? lastNote,

    /// Resumo que o filho devolveu ao terminar.
    String? summary,
    Duration? duration,
  }) = _SubagentRun;

  bool get finished =>
      phase == SubagentPhase.completed ||
      phase == SubagentPhase.failed ||
      phase == SubagentPhase.interrupted;

  SubagentRun apply(SubagentEvent event) {
    final goal = event.goal.isNotEmpty ? event.goal : this.goal;
    final base = copyWith(
      goal: goal,
      taskIndex: event.taskIndex,
      taskCount: event.taskCount,
      depth: event.depth,
    );
    return switch (event.kind) {
      SubagentEventKind.spawnRequested => base.copyWith(
        phase: event.phase ?? SubagentPhase.queued,
      ),
      SubagentEventKind.start => base.copyWith(phase: SubagentPhase.running),
      SubagentEventKind.thinking || SubagentEventKind.progress => base.copyWith(
        phase: finished ? phase : SubagentPhase.running,
        lastNote: event.text ?? lastNote,
      ),
      SubagentEventKind.tool => base.copyWith(
        phase: finished ? phase : SubagentPhase.running,
        toolCalls: toolCalls + 1,
        lastNote: _toolNote(event) ?? lastNote,
      ),
      SubagentEventKind.complete => base.copyWith(
        phase: event.phase ?? SubagentPhase.completed,
        summary: event.summary ?? event.text ?? summary,
        duration: event.duration ?? duration,
      ),
    };
  }
}

String? _toolNote(SubagentEvent event) {
  final note = [
    event.toolName,
    event.toolPreview ?? event.text,
  ].whereType<String>().join(' · ');
  return note.isEmpty ? null : note;
}
