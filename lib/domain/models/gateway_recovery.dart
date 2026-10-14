/// A cursor is scoped to a backend process AND one live session. A durable
/// conversation id alone does not identify an event numbering.
class GatewayReplayCursor {
  const GatewayReplayCursor({
    required this.sessionId,
    required this.epoch,
    required this.seq,
  });
  final String sessionId;
  final String epoch;
  final int seq;
}

enum GatewayRecoveryMode { snapshot, gap, turn }
