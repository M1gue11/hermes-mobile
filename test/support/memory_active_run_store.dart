import 'package:hermes_mobile/data/config/active_run_store.dart';

class MemoryActiveRunStore implements ActiveRunStore {
  final Map<String, ActiveRunRecord> records = {};

  @override
  Future<Set<String>> activeSessionIds() async => records.keys.toSet();

  @override
  Future<ActiveRunRecord?> read(String sessionId) async => records[sessionId];

  @override
  Future<void> save(ActiveRunRecord record) async {
    records[record.sessionId] = record;
  }

  @override
  Future<void> clear(String sessionId) async {
    records.remove(sessionId);
  }
}
