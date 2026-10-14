/// Live or retained failed turn from `session.resume`. It is separate from
/// the durable transcript and may exist even when `running` is false.
class GatewayInflight {
  const GatewayInflight({
    this.user = '',
    this.assistant = '',
    this.streaming = false,
    this.error,
    this.status,
    this.recoverable = false,
    this.corrections = const [],
    this.correctionOffsets = const [],
  });

  final String user;
  final String assistant;
  final bool streaming;
  final String? error;
  final String? status;
  final bool recoverable;
  final List<String> corrections;
  final List<int> correctionOffsets;

  static GatewayInflight? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return GatewayInflight(
      user: raw['user'] is String ? raw['user'] as String : '',
      assistant: raw['assistant'] is String ? raw['assistant'] as String : '',
      streaming: raw['streaming'] == true,
      error: raw['error'] is String ? raw['error'] as String : null,
      status: raw['status'] is String ? raw['status'] as String : null,
      recoverable: raw['recoverable'] == true,
      corrections: raw['corrections'] is List
          ? (raw['corrections'] as List).whereType<String>().toList()
          : const [],
      correctionOffsets: raw['correction_offsets'] is List
          ? (raw['correction_offsets'] as List).whereType<int>().toList()
          : const [],
    );
  }
}
