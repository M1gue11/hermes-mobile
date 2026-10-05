import 'conversation.dart';

/// Página estável de sessões devolvida por `GET /api/sessions`.
class ConversationPage {
  const ConversationPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  final List<Conversation> items;
  final int limit;
  final int offset;
  final bool hasMore;
}
