import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum ActiveTurnTransport { runs, dashboard }

/// Vínculo mínimo necessário para reencontrar um turno depois que o processo do
/// app desaparece. O prompt e a resposta não são duplicados no aparelho: a
/// Runs API ou `session.resume`/`session.history`, conforme [transport], seguem
/// como fontes autoritativas.
class ActiveRunRecord {
  const ActiveRunRecord({
    required this.sessionId,
    required this.runId,
    required this.assistantMessageId,
    required this.startedAt,
    this.model,
    this.transport = ActiveTurnTransport.runs,
  });

  final String sessionId;
  final String runId;
  final String assistantMessageId;
  final DateTime startedAt;
  final String? model;
  final ActiveTurnTransport transport;

  Map<String, dynamic> toJson() => {
    'version': 2,
    'session_id': sessionId,
    'run_id': runId,
    'assistant_message_id': assistantMessageId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'model': model,
    'transport': transport.name,
  };

  static ActiveRunRecord? fromJson(Object? value) {
    if (value is! Map) return null;
    final json = value.map((key, entry) => MapEntry(key.toString(), entry));
    final sessionId = json['session_id']?.toString() ?? '';
    final runId = json['run_id']?.toString() ?? '';
    final assistantMessageId = json['assistant_message_id']?.toString() ?? '';
    final startedAt = DateTime.tryParse(json['started_at']?.toString() ?? '');
    if (sessionId.isEmpty ||
        runId.isEmpty ||
        assistantMessageId.isEmpty ||
        startedAt == null) {
      return null;
    }
    return ActiveRunRecord(
      sessionId: sessionId,
      runId: runId,
      assistantMessageId: assistantMessageId,
      startedAt: startedAt,
      model: json['model']?.toString(),
      transport: switch (json['transport']?.toString()) {
        'dashboard' => ActiveTurnTransport.dashboard,
        _ => ActiveTurnTransport.runs,
      },
    );
  }
}

abstract interface class ActiveRunStore {
  Future<ActiveRunRecord?> read(String sessionId);
  Future<Set<String>> activeSessionIds();
  Future<void> save(ActiveRunRecord record);
  Future<void> clear(String sessionId);
}

/// Usa o armazenamento seguro já adotado pelo pareamento e pela sessão do
/// dashboard. Uma chave por sessão evita disputa entre runs de conversas
/// diferentes e permite que o usuário saia de uma conversa enquanto ela roda.
class SecureActiveRunStore implements ActiveRunStore {
  const SecureActiveRunStore([this._storage = const FlutterSecureStorage()]);

  static const _prefix = 'hermes.active_run.';
  final FlutterSecureStorage _storage;

  String _key(String sessionId) => '$_prefix$sessionId';

  @override
  Future<ActiveRunRecord?> read(String sessionId) async {
    final raw = await _storage.read(key: _key(sessionId));
    if (raw == null) return null;
    try {
      return ActiveRunRecord.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<Set<String>> activeSessionIds() async {
    final values = await _storage.readAll();
    final ids = <String>{};
    for (final entry in values.entries) {
      if (!entry.key.startsWith(_prefix)) continue;
      try {
        final record = ActiveRunRecord.fromJson(jsonDecode(entry.value));
        if (record != null) ids.add(record.sessionId);
      } on FormatException {
        // Um registro quebrado não deve impedir os demais indicadores.
      }
    }
    return ids;
  }

  @override
  Future<void> save(ActiveRunRecord record) => _storage.write(
    key: _key(record.sessionId),
    value: jsonEncode(record.toJson()),
  );

  @override
  Future<void> clear(String sessionId) => _storage.delete(key: _key(sessionId));
}
