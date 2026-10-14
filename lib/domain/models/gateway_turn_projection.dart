import 'chat_message.dart';
import 'gateway_completion.dart';
import 'tool_call.dart';
import 'turn_activity.dart';

/// A projected transcript may omit tool output/details. Only an exact call ID
/// can enrich that projection: equal names are not evidence of the same call.
ToolCall mergeGatewayToolDetails(ToolCall incoming, ToolCall? prior) {
  if (prior == null ||
      incoming.id == null ||
      incoming.id!.trim().isEmpty ||
      incoming.id != prior.id ||
      incoming.name != prior.name) {
    return incoming;
  }
  String? detail(String? value, String? fallback) =>
      value == null || value.isEmpty ? fallback : value;
  return incoming.copyWith(
    arg: incoming.arg.isEmpty ? prior.arg : incoming.arg,
    detail: detail(incoming.detail, prior.detail),
    output: detail(incoming.output, prior.output),
    duration: incoming.duration ?? prior.duration,
    risk: incoming.risk ?? prior.risk,
    outputRedacted: incoming.outputRedacted || prior.outputRedacted,
  );
}

AssistantMessage sealGatewayInterim(
  AssistantMessage message, {
  required String text,
  required bool alreadyStreamed,
  required String id,
}) {
  if (text.isEmpty) return message;
  final items = [...message.activityItems];
  if (!alreadyStreamed && message.text.isNotEmpty) {
    items.add(TurnActivity.commentary(id: '$id-stream', text: message.text));
  }
  items.add(TurnActivity.commentary(id: id, text: text));
  return message.copyWith(activityItems: items, text: '');
}

AssistantMessage settleGatewayResponse(
  AssistantMessage message, {
  String? output,
  GatewayCompletion? completion,
  required String reasoningId,
}) {
  final items = [...message.activityItems];
  var text = message.text;
  final finalText = output ?? '';
  if (completion?.reused != true && finalText.isNotEmpty) {
    final lastCommentary = items.lastIndexWhere((i) => i is TurnCommentary);
    final sealed = lastCommentary < 0
        ? null
        : items[lastCommentary] as TurnCommentary;
    final replacesSealed =
        text.isEmpty &&
        sealed != null &&
        ((completion?.previewed == true && finalText.startsWith(sealed.text)) ||
            (completion?.transformed == true &&
                lastCommentary == items.length - 1));
    if (replacesSealed) {
      items[lastCommentary] = sealed.copyWith(
        text: finalText,
        rowId: completion?.assistantRowId ?? sealed.rowId,
      );
    } else {
      text = finalText;
    }
  }
  var reasoning = message.reasoning;
  final terminalReasoning = completion?.reasoning ?? '';
  if (terminalReasoning.isNotEmpty) {
    final last = items.lastIndexWhere((i) => i is TurnReasoning);
    final prior = last < 0 ? null : items[last] as TurnReasoning;
    if (prior == null) {
      items.add(
        TurnActivity.reasoning(id: reasoningId, text: terminalReasoning),
      );
      reasoning += terminalReasoning;
    } else if (terminalReasoning.startsWith(prior.text)) {
      items[last] = prior.copyWith(text: terminalReasoning);
      if (reasoning.endsWith(prior.text)) {
        reasoning =
            reasoning.substring(0, reasoning.length - prior.text.length) +
            terminalReasoning;
      }
    }
  }
  return message.copyWith(
    text: text,
    activityItems: settleTurnTools(items),
    reasoning: reasoning,
    rowId: completion?.assistantRowId ?? message.rowId,
    warning: completion?.warning ?? message.warning,
    recoverable: completion?.recoverable ?? message.recoverable,
  );
}
