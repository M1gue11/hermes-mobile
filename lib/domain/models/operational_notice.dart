/// Canal operacional: nunca contém argumentos, reasoning ou corpo de subagent.
enum NoticeCategory { progress, completion, error, custom }

enum NoticeLevel { info, success, warning, error }

/// Server metadata when complete; otherwise an explicitly local connection scope.
typedef NoticeSeqScope = ({
  String? sessionId,
  Object? replayEpoch,
  Object? localConnection,
});

enum NoticeOutcome { completed, failed, cancelled }

sealed class OperationalNotice {
  const OperationalNotice({this.id, this.seq, this.seqScope});
  final String? id;
  final int? seq;
  final NoticeSeqScope? seqScope;

  static bool handles(String type) =>
      type == 'notification.show' ||
      type == 'notification.clear' ||
      type == 'background.complete' ||
      const {
        'subagent.spawn_requested',
        'subagent.start',
        'subagent.thinking',
        'subagent.tool',
        'subagent.progress',
        'subagent.complete',
      }.contains(type);

  /// Shape estrito. Identificadores são preservados byte a byte; nunca gerados.
  /// TTL inválido rejeita o show, inclusive negativos, doubles e > 7 dias.
  static OperationalNotice? parse(
    String type,
    Map<String, dynamic> data, {
    int? seq,
    NoticeSeqScope? seqScope,
  }) {
    if (!handles(type)) return null;
    if (data.containsKey('seq') &&
        (data['seq'] is! int ||
            data['seq'] < 0 ||
            data['seq'] > 9007199254740991)) {
      return null;
    }
    seq ??= data['seq'] as int?;
    if (seq != null && (seq < 0 || seq > 9007199254740991)) return null;
    String? identifier(Object? value) =>
        value is String && value.isNotEmpty && value.runes.length <= 256
        ? value
        : null;
    final id = identifier(data['id']);
    if (data['id'] != null && id == null) return null;
    if (type == 'notification.clear') {
      final key = identifier(data['key']);
      return key == null
          ? null
          : NoticeClear(key: key, seq: seq, seqScope: seqScope);
    }
    if (type == 'notification.show') {
      final key = identifier(data['key']);
      final kind = identifier(data['kind']);
      final level = switch (data['level']) {
        'info' => NoticeLevel.info,
        'success' => NoticeLevel.success,
        'warn' || 'warning' => NoticeLevel.warning,
        'error' => NoticeLevel.error,
        _ => null,
      };
      final text = data['text'];
      final ttl = data['ttl_ms'];
      if ((data['key'] != null && key == null) ||
          kind == null ||
          level == null ||
          text is! String ||
          text.isEmpty ||
          (ttl != null && (ttl is! int || ttl < 0 || ttl > 604800000))) {
        return null;
      }
      return NoticeShow(
        id: id,
        seq: seq,
        seqScope: seqScope,
        key: key,
        kind: kind,
        level: level,
        text: String.fromCharCodes(text.runes.take(1000)),
        ttlMs: ttl as int?,
      );
    }
    final taskField = type == 'background.complete' ? 'task_id' : 'subagent_id';
    final task = identifier(data[taskField]);
    if (data[taskField] != null && task == null) return null;
    final outcome = type != 'subagent.complete'
        ? null
        : switch (data['status']) {
            'complete' || 'completed' => NoticeOutcome.completed,
            'error' || 'failed' || 'timeout' => NoticeOutcome.failed,
            'interrupted' || 'cancelled' => NoticeOutcome.cancelled,
            _ => null,
          };
    return NoticeSignal(
      type: type,
      taskId: task,
      id: id,
      seq: seq,
      seqScope: seqScope,
      outcome: outcome,
    );
  }
}

final class NoticeShow extends OperationalNotice {
  const NoticeShow({
    super.id,
    super.seq,
    super.seqScope,
    this.key,
    required this.kind,
    required this.level,
    required this.text,
    this.ttlMs,
  });
  final String? key;
  final String kind;
  final NoticeLevel level;
  final String text;
  final int? ttlMs;
}

final class NoticeClear extends OperationalNotice {
  const NoticeClear({required this.key, super.seq, super.seqScope});
  final String key;
}

final class NoticeSignal extends OperationalNotice {
  const NoticeSignal({
    required this.type,
    this.taskId,
    super.id,
    super.seq,
    super.seqScope,
    this.outcome,
  });
  final String type;
  final String? taskId;
  final NoticeOutcome? outcome;
}
