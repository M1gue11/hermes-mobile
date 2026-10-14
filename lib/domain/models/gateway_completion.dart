/// Terminal metadata from the TUI wire. Text identity comes from turn
/// boundaries and explicit reuse/transform flags, never equal words alone.
class GatewayCompletion {
  const GatewayCompletion({
    this.previewed = false,
    this.reused = false,
    this.transformed = false,
    this.partial = false,
    this.recoverable = false,
    this.reasoning,
    this.warning,
    this.userRowId,
    this.assistantRowId,
    this.persisted = false,
  });
  final bool previewed;
  final bool reused;
  final bool transformed;
  final bool partial;
  final bool recoverable;
  final String? reasoning;
  final String? warning;
  final int? userRowId;
  final int? assistantRowId;
  final bool persisted;

  factory GatewayCompletion.fromJson(Map<String, dynamic> json) {
    final receipt = json['persisted_turn'];
    return GatewayCompletion(
      previewed: json['response_previewed'] == true,
      reused: json['response_reused'] == true,
      transformed: json['response_transformed'] == true,
      partial: json['partial'] == true,
      recoverable: json['recoverable'] == true,
      reasoning: json['reasoning'] is String
          ? json['reasoning'] as String
          : null,
      warning: json['warning'] is String ? json['warning'] as String : null,
      userRowId: receipt is Map && receipt['user_row_id'] is int
          ? receipt['user_row_id'] as int
          : null,
      assistantRowId: receipt is Map && receipt['final_assistant_row_id'] is int
          ? receipt['final_assistant_row_id'] as int
          : null,
      persisted: receipt is Map && receipt['complete'] == true,
    );
  }
}
