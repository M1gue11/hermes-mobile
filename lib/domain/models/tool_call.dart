import 'package:freezed_annotation/freezed_annotation.dart';

part 'tool_call.freezed.dart';

/// Estado de uma chamada de ferramenta na timeline (o protótipo mostra `exec`
/// enquanto roda e `ok` ao terminar).
enum ToolStatus { running, done, error }

/// Uma tool call do agente, renderizada na timeline SEPARADA do texto final
/// (regra de UX da Runs API: nunca misturar progresso de ferramenta com a
/// resposta do assistant).
@freezed
abstract class ToolCall with _$ToolCall {
  const factory ToolCall({
    String? id,
    required String name,
    @Default('') String arg,
    String? detail,
    String? output,
    String? duration,
    @Default(ToolStatus.running) ToolStatus status,
  }) = _ToolCall;
}
