import 'dart:async';

/// Relógio determinístico sem dependência adicional.
class NoticeClock {
  DateTime value = DateTime.utc(2026, 10, 7);
  final timers = <_NoticeTimer>[];
  DateTime now() => value;
  Timer timer(Duration delay, void Function() callback) {
    final timer = _NoticeTimer(value.add(delay), callback);
    timers.add(timer);
    return timer;
  }

  int get activeTimers => timers.where((t) => t.isActive).length;
  void advance(Duration delta) {
    final end = value.add(delta);
    while (true) {
      final due = timers.where((t) => t.isActive && !t.at.isAfter(end)).toList()
        ..sort((a, b) => a.at.compareTo(b.at));
      if (due.isEmpty) break;
      final next = due.first;
      value = next.at;
      next.fire();
    }
    value = end;
  }
}

class _NoticeTimer implements Timer {
  _NoticeTimer(this.at, this.callback);
  final DateTime at;
  final void Function() callback;
  bool _active = true;
  int _tick = 0;
  @override
  bool get isActive => _active;
  @override
  int get tick => _tick;
  @override
  void cancel() => _active = false;
  void fire() {
    if (!_active) return;
    _active = false;
    _tick++;
    callback();
  }
}
