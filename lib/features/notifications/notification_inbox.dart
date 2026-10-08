import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/operational_notice.dart';

final notificationInboxProvider = Provider<NotificationInbox>((ref) {
  final inbox = NotificationInbox();
  ref.onDispose(inbox.dispose);
  return inbox;
});

typedef NoticeTimer = Timer Function(Duration delay, void Function() callback);
typedef _Scope = (String, String);
typedef NoticeSlot = (String, String, String, String?);

enum NoticeProvenance { remoteSignal, localProvisional, remoteTerminal }

/// Identidade local é separada de id/key do servidor. Nada aqui é persistido.
class InboxEntry {
  const InboxEntry({
    required this.localId,
    required this.sessionId,
    required this.category,
    required this.origin,
    required this.level,
    required this.text,
    required this.createdAt,
    required this.slot,
    this.provenance = NoticeProvenance.remoteSignal,
    this.serverId,
    this.seq,
    this.key,
    this.kind,
    this.expiresAt,
    this.read = false,
  });
  final NoticeProvenance provenance;
  final int localId;
  final String sessionId;
  final NoticeCategory category;
  final String origin;
  final NoticeLevel level;
  final String text;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? serverId;
  final int? seq;
  final String? key;
  final String? kind;
  final bool read;
  final NoticeSlot slot;

  String get location => '/chat/${Uri.encodeComponent(sessionId)}';
  InboxEntry asRead() => InboxEntry(
    provenance: provenance,
    localId: localId,
    sessionId: sessionId,
    category: category,
    origin: origin,
    level: level,
    text: text,
    createdAt: createdAt,
    slot: slot,
    serverId: serverId,
    seq: seq,
    key: key,
    kind: kind,
    expiresAt: expiresAt,
    read: true,
  );
}

/// Inbox LOCAL de sinais live. Sem replay garantido, conexão ou ponte OS.
class NotificationInbox extends ChangeNotifier {
  NotificationInbox({DateTime Function()? now, NoticeTimer? timer})
    : _now = now ?? DateTime.now,
      _timer = timer ?? Timer.new;
  static const maxEntries = 100;
  static const maxCache = 256;
  static const maxPending = 32;
  static const progressDelay = Duration(milliseconds: 750);
  final DateTime Function() _now;
  final NoticeTimer _timer;
  final _entries = <InboxEntry>[];
  final _expiry = <int, Timer>{};
  final _pending = <NoticeSlot, (InboxEntry, Timer)>{};
  final _seen = <Object>{};
  final _terminal = <_Scope>{};
  final _cancelRequested = <_Scope>{};
  final _finishedTasks = <NoticeSlot>{};
  final _enabled = {for (final c in NoticeCategory.values) c: true};
  final Object _localIngressScope = Object();
  int _serial = 0;
  bool _disposed = false;

  List<InboxEntry> get entries => List.unmodifiable(_entries.reversed);
  int get unread => _entries.where((e) => !e.read).length;
  bool enabled(NoticeCategory category) => _enabled[category]!;

  void setEnabled(NoticeCategory category, bool value) {
    if (_disposed || enabled(category) == value) return;
    _enabled[category] = value;
    if (!value) {
      for (final slot in _pending.keys.toList()) {
        if (_pending[slot]!.$1.category == category) _cancel(slot);
      }
    }
    notifyListeners();
  }

  void markRead(int localId) {
    if (_disposed) return;
    final index = _entries.indexWhere((e) => e.localId == localId);
    if (index < 0 || _entries[index].read) return;
    _entries[index] = _entries[index].asRead();
    notifyListeners();
  }

  void remove(int localId) {
    if (_disposed) return;
    _expiry.remove(localId)?.cancel();
    _entries.removeWhere((e) => e.localId == localId);
    notifyListeners();
  }

  void cancelPending() {
    for (final slot in _pending.keys.toList()) {
      _cancel(slot);
    }
  }

  void _cancel(NoticeSlot slot) {
    _pending.remove(slot)?.$2.cancel();
  }

  void _remember<T>(Set<T> cache, T key) {
    cache.add(key);
    while (cache.length > maxCache) {
      cache.remove(cache.first);
    }
  }

  bool _duplicate(String session, OperationalNotice notice) {
    final type = switch (notice) {
      NoticeShow() => 'show',
      NoticeClear() => 'clear',
      NoticeSignal(:final type) => type,
    };
    final keys = <Object>[
      if (notice is NoticeSignal && notice.id != null)
        (session, type, 'id', notice.id),
      if (notice.seq != null)
        (
          session,
          notice.seqScope ??
              (
                sessionId: null,
                replayEpoch: null,
                localConnection: _localIngressScope,
              ),
          'seq',
          notice.seq,
        ),
    ];
    final duplicate = keys.any(_seen.contains);
    for (final key in keys) {
      _remember(_seen, key);
    }
    if (duplicate) return true;
    // Show IDs identify reusable notices. Without seq only active, bounded
    // payload equality is distinguishable from a real update/re-emission.
    if (notice is NoticeShow && notice.seq == null && notice.id != null) {
      final text = String.fromCharCodes(notice.text.runes.take(1000));
      return _entries.any(
        (entry) =>
            entry.sessionId == session &&
            entry.category == NoticeCategory.custom &&
            entry.serverId == notice.id &&
            entry.key == notice.key &&
            entry.kind == notice.kind &&
            entry.level == notice.level &&
            entry.text == text &&
            entry.expiresAt?.difference(entry.createdAt).inMilliseconds ==
                notice.ttlMs,
      );
    }
    return false;
  }

  void accept(String session, String run, OperationalNotice notice) {
    if (_disposed || session.isEmpty || _duplicate(session, notice)) {
      return;
    }
    switch (notice) {
      case NoticeClear(:final key):
        for (final e
            in _entries
                .where((e) => e.sessionId == session && e.key == key)
                .toList()) {
          remove(e.localId);
        }
      case NoticeShow():
        if (!enabled(NoticeCategory.custom)) return;
        final now = _now();
        final ttl = notice.ttlMs;
        // Defesa também para chamadas tipadas internas, sem overflow DateTime.
        if (ttl != null &&
            (ttl < 0 ||
                ttl > 604800000 ||
                now.millisecondsSinceEpoch > 8640000000000000 - ttl)) {
          return;
        }
        final slot = (
          session,
          '',
          notice.key != null
              ? 'custom'
              : notice.id != null
              ? 'custom-id'
              : 'custom-local',
          notice.key ?? notice.id ?? 'local-${_serial + 1}',
        );
        final entry = InboxEntry(
          localId: ++_serial,
          sessionId: session,
          category: NoticeCategory.custom,
          origin: 'Agente',
          level: notice.level,
          text: String.fromCharCodes(notice.text.runes.take(1000)),
          createdAt: now,
          slot: slot,
          serverId: notice.id,
          seq: notice.seq,
          key: notice.key,
          kind: notice.kind,
          expiresAt: ttl == null ? null : now.add(Duration(milliseconds: ttl)),
        );
        _put(entry);
      case NoticeSignal():
        if (!OperationalNotice.handles(notice.type)) return;
        final background = notice.type == 'background.complete';
        if (!background && _terminal.contains((session, run))) return;
        final complete = background || notice.type == 'subagent.complete';
        final slot = (
          session,
          run,
          background ? 'background' : 'subagent',
          notice.taskId,
        );
        if (!complete && _finishedTasks.contains(slot)) return;
        if (complete) {
          if (_finishedTasks.contains(slot)) return;
          _remember(_finishedTasks, slot);
          _cancel(slot);
        }
        final failed = complete && notice.outcome == NoticeOutcome.failed;
        final category = failed
            ? NoticeCategory.error
            : complete
            ? NoticeCategory.completion
            : NoticeCategory.progress;
        if (!enabled(category)) return;
        final text = background
            ? 'Trabalho em segundo plano concluído.'
            : switch (notice.type) {
                'subagent.spawn_requested' => 'Delegação solicitada.',
                'subagent.start' => 'Delegação iniciada.',
                'subagent.thinking' => 'Delegação em andamento.',
                'subagent.tool' => 'Delegação usando ferramentas.',
                'subagent.complete' =>
                  failed
                      ? 'A delegação falhou.'
                      : notice.outcome == NoticeOutcome.cancelled
                      ? 'Delegação interrompida.'
                      : 'Delegação encerrada.',
                _ => 'Delegação em andamento.',
              };
        final entry = InboxEntry(
          localId: ++_serial,
          sessionId: session,
          category: category,
          origin: background ? 'Segundo plano' : 'Delegação',
          level: failed
              ? NoticeLevel.error
              : background || notice.outcome == NoticeOutcome.completed
              ? NoticeLevel.success
              : NoticeLevel.info,
          text: text,
          createdAt: _now(),
          slot: slot,
          serverId: notice.id,
          seq: notice.seq,
        );
        if (complete) {
          _put(entry);
        } else {
          _schedule(entry);
        }
    }
  }

  /// Id local do turno vem do controller; nunca exposto como id do servidor.
  void run(
    String session,
    String run,
    NoticeCategory category, {
    bool cancelled = false,
    bool cancelRequested = false,
    bool observerError = false,
    bool toolsInProgress = false,
    bool inProgress = false,
  }) {
    if (_disposed || session.isEmpty) return;
    final scope = (session, run);
    final terminal =
        category != NoticeCategory.progress &&
        !cancelRequested &&
        !observerError;
    if (_terminal.contains(scope)) return;
    if (_cancelRequested.contains(scope) &&
        (cancelRequested || category == NoticeCategory.progress)) {
      return;
    }
    if (cancelRequested) _remember(_cancelRequested, scope);
    if (terminal || cancelRequested || observerError) {
      if (terminal) _remember(_terminal, scope);
      for (final slot in _pending.keys.toList()) {
        if (slot.$1 == session && slot.$2 == run) _cancel(slot);
      }
    }
    if (!enabled(category)) return;
    final entry = InboxEntry(
      localId: ++_serial,
      sessionId: session,
      category: category,
      provenance: terminal
          ? NoticeProvenance.remoteTerminal
          : cancelRequested || observerError
          ? NoticeProvenance.localProvisional
          : NoticeProvenance.remoteSignal,
      origin: 'Execução',
      level: cancelled || cancelRequested
          ? NoticeLevel.info
          : category == NoticeCategory.error
          ? NoticeLevel.error
          : terminal
          ? NoticeLevel.success
          : NoticeLevel.info,
      text: observerError
          ? 'Não foi possível acompanhar a execução.'
          : toolsInProgress
          ? 'Ferramentas em andamento.'
          : cancelRequested
          ? 'Interrupção solicitada.'
          : cancelled
          ? 'Execução interrompida.'
          : switch (category) {
              NoticeCategory.progress =>
                inProgress ? 'Execução em andamento.' : 'Execução iniciada.',
              NoticeCategory.error => 'A execução falhou.',
              _ => 'Execução concluída.',
            },
      createdAt: _now(),
      slot: (session, run, 'run', null),
    );
    if (terminal || cancelRequested || observerError) {
      _put(entry);
    } else {
      _schedule(entry);
    }
  }

  void _schedule(InboxEntry entry) {
    if (_disposed || !enabled(entry.category)) return;
    if (_entries.any(
      (old) =>
          old.slot == entry.slot &&
          old.text == entry.text &&
          old.category == entry.category,
    )) {
      _cancel(entry.slot);
      return;
    }
    final previous = _pending[entry.slot];
    if (previous != null) {
      _pending[entry.slot] = (entry, previous.$2);
      return;
    }
    if (_pending.length >= maxPending) _cancel(_pending.keys.first);
    final timer = _timer(progressDelay, () {
      final pending = _pending.remove(entry.slot);
      if (!_disposed && pending != null && enabled(pending.$1.category)) {
        _put(pending.$1);
      }
    });
    _pending[entry.slot] = (entry, timer);
  }

  void _put(InboxEntry entry) {
    if (_disposed) return;
    for (final old in _entries.where((e) => e.slot == entry.slot).toList()) {
      _expiry.remove(old.localId)?.cancel();
      _entries.remove(old);
    }
    final expiry = entry.expiresAt;
    if (expiry != null && !expiry.isAfter(_now())) {
      notifyListeners();
      return;
    }
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _expiry.remove(_entries.removeAt(0).localId)?.cancel();
    }
    if (expiry != null) {
      _expiry[entry.localId] = _timer(
        expiry.difference(_now()),
        () => remove(entry.localId),
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelPending();
    for (final timer in _expiry.values) {
      timer.cancel();
    }
    _expiry.clear();
    _entries.clear();
    _seen.clear();
    _terminal.clear();
    _cancelRequested.clear();
    _finishedTasks.clear();
    super.dispose();
  }
}
